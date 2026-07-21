#!/usr/bin/env bash
# scan-secrets.sh — blocks the send if the file contains a secret.
# Usage: scripts/scan-secrets.sh <file>
# Exit 0 = clean. Exit 1 = secret detected (abort). Exit 2 = usage/IO error.

set -euo pipefail

FILE="${1:-}"
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  echo "[scan-secrets] ERROR: file not found: $FILE" >&2
  exit 2
fi

# Known secret formats (API keys, tokens, private keys).
PATTERNS=(
  'sk-[A-Za-z0-9_-]{20,}'
  'sk-ant-[A-Za-z0-9_-]{20,}'
  'ghp_[A-Za-z0-9]{30,}'
  'gho_[A-Za-z0-9]{30,}'
  'github_pat_[A-Za-z0-9_]{40,}'
  'AKIA[0-9A-Z]{16}'
  'ASIA[0-9A-Z]{16}'
  'AIza[0-9A-Za-z_-]{35}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'
  '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP |)PRIVATE KEY-----'
  'hf_[A-Za-z0-9]{30,}'
  'glpat-[A-Za-z0-9_-]{20,}'
)

# Sensitive path patterns — a docmail should never mention where your secrets live.
# Add your own regexes here (e.g. your password-store or secrets directory).
FORBIDDEN_PATHS=(
  '[\\/]\.ssh[\\/]'
  '[\\/]\.gnupg[\\/]'
)

FOUND=0
MATCHES=""

for pat in "${PATTERNS[@]}"; do
  if hit=$(grep -En "$pat" "$FILE" 2>/dev/null | head -3); then
    if [[ -n "$hit" ]]; then
      FOUND=1
      MATCHES+=$'\n'"[pattern: ${pat:0:40}...]"$'\n'"$hit"
    fi
  fi
done

for path in "${FORBIDDEN_PATHS[@]}"; do
  if hit=$(grep -EniI "$path" "$FILE" 2>/dev/null | head -3); then
    if [[ -n "$hit" ]]; then
      FOUND=1
      MATCHES+=$'\n'"[forbidden path: $path]"$'\n'"$hit"
    fi
  fi
done

if [[ "$FOUND" -eq 1 ]]; then
  echo "[scan-secrets] BLOCKED — secret(s) detected in $FILE" >&2
  echo "$MATCHES" >&2
  echo "[scan-secrets] Fix the file (remove/mask) then retry." >&2
  exit 1
fi

echo "[scan-secrets] OK — $FILE clean"
exit 0
