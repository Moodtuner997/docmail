#!/usr/bin/env bash
# send-webhook.sh — robust docmail send.
# Usage: scripts/send-webhook.sh <filename.html> <mode> <subject>
# Exit 0 = sent. 1 = secret detected. 2 = HTTP non-2xx. 3 = usage/IO error.
#
# Reads its configuration from $DOCMAIL_CONF (default: ~/docmail.conf):
#   DOCMAIL_HOME, DOCMAIL_WEBHOOK_URL, DOCMAIL_SECRETS_DIR
# DOCMAIL_TOKEN can also be provided as an environment variable.

set -euo pipefail

FILE="${1:-}"
MODE="${2:-batch}"
SUBJECT="${3:-[Docmail]}"

# Intent guard: the mode changes what the receiver does with the POST.
# A manual call without arg 2 silently falls back to "batch" -> ambiguous intent.
# The morning cron ALWAYS passes "batch" explicitly -> never affected here.
if [[ -z "${2:-}" ]]; then
  echo "[send-webhook] WARNING: mode not specified -> defaulting to \"batch\". For an immediate send, pass \"instant\" as 2nd argument." >&2
fi

# ── Load config ──────────────────────────────
CONF="${DOCMAIL_CONF:-$HOME/docmail.conf}"
if [[ -f "$CONF" ]]; then
  # shellcheck source=/dev/null
  source "$CONF"
fi

if [[ -z "${DOCMAIL_HOME:-}" ]]; then
  echo "[send-webhook] ERROR: DOCMAIL_HOME not set (edit $CONF)" >&2
  exit 3
fi
if [[ -z "${DOCMAIL_WEBHOOK_URL:-}" ]]; then
  echo "[send-webhook] ERROR: DOCMAIL_WEBHOOK_URL not set (edit $CONF or export it)" >&2
  exit 3
fi

WEBHOOK_URL="$DOCMAIL_WEBHOOK_URL"
QUEUE_DIR="$DOCMAIL_HOME/queue"
SENT_DIR="$DOCMAIL_HOME/sent"
FAILED_DIR="$DOCMAIL_HOME/failed"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$QUEUE_DIR" "$SENT_DIR" "$FAILED_DIR"

if [[ -z "$FILE" || ! -f "$QUEUE_DIR/$FILE" ]]; then
  echo "[send-webhook] ERROR: file not found: $QUEUE_DIR/$FILE" >&2
  echo "[send-webhook] Reminder: pass the FILENAME only, not a path — the script prefixes queue/ itself." >&2
  exit 3
fi

# ── Secret scan (hard gate) ──────────────────
if ! "$SCRIPT_DIR/scan-secrets.sh" "$QUEUE_DIR/$FILE"; then
  mv "$QUEUE_DIR/$FILE" "$FAILED_DIR/$FILE.secret-blocked" || true
  echo "[send-webhook] ABORT: secret detected, moved to failed/" >&2
  exit 1
fi

# ── Token ────────────────────────────────────
if [[ -z "${DOCMAIL_TOKEN:-}" && -n "${DOCMAIL_SECRETS_DIR:-}" && -f "$DOCMAIL_SECRETS_DIR/DOCMAIL_TOKEN" ]]; then
  DOCMAIL_TOKEN="$(tr -d '\r\n' < "$DOCMAIL_SECRETS_DIR/DOCMAIL_TOKEN")"
fi
if [[ -z "${DOCMAIL_TOKEN:-}" ]]; then
  echo "[send-webhook] ERROR: DOCMAIL_TOKEN not set (env var or \$DOCMAIL_SECRETS_DIR/DOCMAIL_TOKEN file)" >&2
  exit 3
fi

# ── Build JSON payload ───────────────────────
# jq --rawfile reads the HTML from disk (avoids ARG_MAX limits on large docs)
# and curl --data-binary @file posts it. python3 fallback if jq is missing.
TMP_BODY=$(mktemp)
TMP_PAYLOAD=$(mktemp)
TMP_ERR=$(mktemp)
trap 'rm -f "$TMP_BODY" "$TMP_PAYLOAD" "$TMP_ERR" 2>/dev/null' EXIT

if command -v jq >/dev/null 2>&1; then
  jq -n \
    --arg mode "$MODE" \
    --arg filename "$FILE" \
    --arg subject "$SUBJECT" \
    --rawfile content "$QUEUE_DIR/$FILE" \
    '{mode:$mode,filename:$filename,subject:$subject,content:$content}' \
    > "$TMP_PAYLOAD"
else
  MODE="$MODE" FILE="$FILE" SUBJECT="$SUBJECT" SRC="$QUEUE_DIR/$FILE" python3 -c '
import json, os
print(json.dumps({
    "mode": os.environ["MODE"],
    "filename": os.environ["FILE"],
    "subject": os.environ["SUBJECT"],
    "content": open(os.environ["SRC"], encoding="utf-8").read(),
}))' > "$TMP_PAYLOAD"
fi

# ── POST ─────────────────────────────────────
do_post() {
  curl -sS -o "$TMP_BODY" -w "%{http_code}" -X POST \
    "$WEBHOOK_URL" \
    -H "Authorization: Bearer $DOCMAIL_TOKEN" \
    -H "Content-Type: application/json" \
    --max-time 15 \
    --retry 3 --retry-delay 2 --retry-connrefused \
    --data-binary @"$TMP_PAYLOAD" 2>"$TMP_ERR" || echo "000"
}

HTTP_CODE=$(do_post)

# DNS auto-recovery: code 000 is often a resolution failure (negative DNS cache
# on Windows; curl's --retry-connrefused does NOT cover resolution failures).
# Flush the DNS cache and retry ONCE. Guard: only if ipconfig exists (Windows);
# on Linux (cron) ipconfig doesn't exist -> no flush, behavior unchanged.
if [[ "$HTTP_CODE" == "000" ]] && command -v ipconfig >/dev/null 2>&1; then
  echo "[send-webhook] code 000 (DNS resolution?) — flushing local DNS cache + retry" >&2
  ipconfig //flushdns >/dev/null 2>&1 || true
  HTTP_CODE=$(do_post)
fi

# ── Outcome ──────────────────────────────────
if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
  mv "$QUEUE_DIR/$FILE" "$SENT_DIR/$FILE"
  touch "$SENT_DIR/$FILE.sent"
  echo "[send-webhook] OK $HTTP_CODE — $FILE -> sent/"
  # Delivery guard: most webhook receivers return 2xx on RECEIPT of the POST,
  # before the actual email send. 2xx = request accepted, NOT proof of delivery.
  echo "[send-webhook] REMINDER: 2xx = POST received by the webhook, NOT proof of email delivery. Check your inbox before declaring \"sent\"." >&2
  exit 0
else
  cp "$TMP_BODY" "$FAILED_DIR/$FILE.http-$HTTP_CODE.log" 2>/dev/null || true
  if [[ -s "$TMP_ERR" ]]; then
    cp "$TMP_ERR" "$FAILED_DIR/$FILE.curl-err.log" 2>/dev/null || true
  fi
  echo "[send-webhook] FAIL HTTP=$HTTP_CODE — $FILE stays in queue/, log in failed/" >&2
  exit 2
fi
