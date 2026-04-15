#!/usr/bin/env bash
# ──────────────────────────────────────────────
# Docmail — Setup script
# Reads docmail.conf and patches placeholders in skill + workflow files
# ──────────────────────────────────────────────
set -euo pipefail

CONF="${DOCMAIL_CONF:-$HOME/docmail.conf}"

if [[ ! -f "$CONF" ]]; then
  echo "ERROR: Config file not found: $CONF"
  echo "Copy docmail.conf.example to $CONF and fill in your values."
  exit 1
fi

# shellcheck source=/dev/null
source "$CONF"

# Validate required fields
missing=()
[[ -z "${DOCMAIL_OUTPUT_DIR:-}" ]] && missing+=("DOCMAIL_OUTPUT_DIR")
[[ -z "${DOCMAIL_SECRETS_DIR:-}" ]] && missing+=("DOCMAIL_SECRETS_DIR")
[[ -z "${DOCMAIL_WEBHOOK_URL:-}" ]] && missing+=("DOCMAIL_WEBHOOK_URL")
[[ -z "${N8N_DOCMAIL_DIR:-}" ]] && missing+=("N8N_DOCMAIL_DIR")
[[ -z "${N8N_SMTP_CREDENTIAL_ID:-}" ]] && missing+=("N8N_SMTP_CREDENTIAL_ID")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "ERROR: Missing required config values:"
  for m in "${missing[@]}"; do echo "  - $m"; done
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Patching skill file..."
sed \
  -e "s|<YOUR_DOCMAIL_OUTPUT_DIR>|${DOCMAIL_OUTPUT_DIR}|g" \
  -e "s|<YOUR_SECRETS_DIR>|${DOCMAIL_SECRETS_DIR}|g" \
  -e "s|<YOUR_WEBHOOK_URL>|${DOCMAIL_WEBHOOK_URL}|g" \
  -e "s|<YOUR_VOICE_DEFINITIONS_PATH>|${DOCMAIL_VOICE_DEFS:-./voices}|g" \
  "$SCRIPT_DIR/skill/SKILL.md" > "$SCRIPT_DIR/skill/SKILL.local.md"

echo "Patching receiver workflow..."
sed \
  -e "s|/home/node/docmail|${N8N_DOCMAIL_DIR}|g" \
  -e "s|YOUR_SMTP_CREDENTIAL_ID|${N8N_SMTP_CREDENTIAL_ID}|g" \
  -e "s|SMTP account|${N8N_SMTP_CREDENTIAL_NAME:-SMTP account}|g" \
  "$SCRIPT_DIR/workflows/docmail-receiver.json" > "$SCRIPT_DIR/workflows/docmail-receiver.local.json"

echo "Patching morning recap workflow..."
sed \
  -e "s|/home/node/docmail|${N8N_DOCMAIL_DIR}|g" \
  -e "s|YOUR_SMTP_CREDENTIAL_ID|${N8N_SMTP_CREDENTIAL_ID}|g" \
  -e "s|SMTP account|${N8N_SMTP_CREDENTIAL_NAME:-SMTP account}|g" \
  -e "s|Europe/Paris|${DOCMAIL_TIMEZONE:-Europe/Paris}|g" \
  -e "s|\"triggerAtHour\": 8|\"triggerAtHour\": ${DOCMAIL_RECAP_HOUR:-8}|g" \
  "$SCRIPT_DIR/workflows/docmail-morning-recap.json" > "$SCRIPT_DIR/workflows/docmail-morning-recap.local.json"

echo ""
echo "Done! Generated files:"
echo "  skill/SKILL.local.md                          — Install in ~/.claude/skills/docmail/"
echo "  workflows/docmail-receiver.local.json          — Import in n8n"
echo "  workflows/docmail-morning-recap.local.json     — Import in n8n"
echo ""
echo "Next steps:"
echo "  1. Create your token:  openssl rand -hex 32 > ${DOCMAIL_SECRETS_DIR}/DOCMAIL_TOKEN"
echo "  2. Set DOCMAIL_TOKEN env var in n8n to the same value"
echo "  3. Set SMTP_USER env var in n8n to your email address"
echo "  4. Import the .local.json workflows in n8n"
echo "  5. Copy SKILL.local.md to your Claude Code skills directory"
echo "  6. Create the server directory:  mkdir -p ${N8N_DOCMAIL_DIR}/archive"
