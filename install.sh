#!/usr/bin/env bash
# ──────────────────────────────────────────────
# Docmail — Installer
# Reads config, creates directories, installs the skill (+ scripts), prepares n8n workflows
# ──────────────────────────────────────────────
set -euo pipefail

# ── Colors ───────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[info]${NC}  $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $*"; }
fail()  { echo -e "${RED}[err]${NC}   $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="${DOCMAIL_CONF:-$HOME/docmail.conf}"

# ── Banner ───────────────────────────────────
echo ""
echo -e "${BOLD}docmail installer${NC}"
echo "─────────────────────────────────────────"
echo ""

# ── Step 1: Config file ─────────────────────
if [[ ! -f "$CONF" ]]; then
  if [[ "${1:-}" == "--init" ]]; then
    info "Creating config from template..."
    cp "$SCRIPT_DIR/docmail.conf.example" "$CONF"
    chmod 600 "$CONF"
    ok "Config created at $CONF"
    echo ""
    echo -e "${YELLOW}Edit it with your values, then re-run:${NC}"
    echo "  nano $CONF"
    echo "  bash install.sh"
    exit 0
  fi
  fail "Config not found: $CONF\n  Run ${BOLD}bash install.sh --init${NC} to create it from template,\n  or copy manually: cp docmail.conf.example $CONF"
fi

info "Loading config from $CONF"
# shellcheck source=/dev/null
source "$CONF"

# v1 -> v2 migration hint
if [[ -z "${DOCMAIL_HOME:-}" && -n "${DOCMAIL_OUTPUT_DIR:-}" ]]; then
  fail "v2 uses DOCMAIL_HOME (base dir with queue/, sent/, failed/) instead of DOCMAIL_OUTPUT_DIR.\n  Add to $CONF:  DOCMAIL_HOME=\"<base directory>\"  (see docmail.conf.example)"
fi

# ── Step 2: Validate required fields ────────
missing=()
[[ -z "${DOCMAIL_HOME:-}" ]]         && missing+=("DOCMAIL_HOME")
[[ -z "${DOCMAIL_SECRETS_DIR:-}" ]]  && missing+=("DOCMAIL_SECRETS_DIR")
[[ -z "${DOCMAIL_WEBHOOK_URL:-}" ]]  && missing+=("DOCMAIL_WEBHOOK_URL")

if [[ ${#missing[@]} -gt 0 ]]; then
  fail "Missing required values in $CONF:\n$(printf '  - %s\n' "${missing[@]}")"
fi

# Warn on placeholder values still present
for var in DOCMAIL_HOME DOCMAIL_SECRETS_DIR DOCMAIL_WEBHOOK_URL; do
  val="${!var}"
  if [[ "$val" == */path/to/* ]] || [[ "$val" == *example.com* ]] || [[ "$val" == *your-* ]]; then
    fail "$var still contains a placeholder value: $val\n  Edit $CONF with your real values."
  fi
done

ok "Config validated"

# ── Step 3: Create local directories ────────
for sub in queue sent failed; do
  if [[ ! -d "$DOCMAIL_HOME/$sub" ]]; then
    mkdir -p "$DOCMAIL_HOME/$sub"
    ok "Created $DOCMAIL_HOME/$sub"
  fi
done
ok "Document directories ready: $DOCMAIL_HOME/{queue,sent,failed}"

# ── Step 4: Create secrets directory ────────
if [[ ! -d "$DOCMAIL_SECRETS_DIR" ]]; then
  info "Creating secrets directory: $DOCMAIL_SECRETS_DIR"
  mkdir -p "$DOCMAIL_SECRETS_DIR"
  chmod 700 "$DOCMAIL_SECRETS_DIR"
  ok "Created $DOCMAIL_SECRETS_DIR (mode 700)"
else
  ok "Secrets directory exists: $DOCMAIL_SECRETS_DIR"
fi

# ── Step 5: Generate token if missing ───────
TOKEN_FILE="$DOCMAIL_SECRETS_DIR/DOCMAIL_TOKEN"
if [[ ! -f "$TOKEN_FILE" ]]; then
  info "Generating authentication token..."
  openssl rand -hex 32 > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  ok "Token generated at $TOKEN_FILE (mode 600)"
  echo ""
  warn "Copy this token to your webhook server as env var DOCMAIL_TOKEN:"
  echo -e "  ${BOLD}$(cat "$TOKEN_FILE")${NC}"
  echo ""
else
  ok "Token file exists: $TOKEN_FILE"
fi

# ── Step 6: Patch skill file ────────────────
info "Patching skill..."
SKILL_OUT="$SCRIPT_DIR/skill/SKILL.local.md"
sed \
  -e "s|<YOUR_DOCMAIL_HOME>|${DOCMAIL_HOME}|g" \
  -e "s|<YOUR_VOICE_DEFINITIONS_PATH>|${DOCMAIL_VOICE_DEFS:-none - using the built-in table}|g" \
  "$SCRIPT_DIR/skill/SKILL.md" > "$SKILL_OUT"
ok "Patched → skill/SKILL.local.md"

# ── Step 7: Patch n8n workflows (optional) ──
if [[ -n "${N8N_DOCMAIL_DIR:-}" && -n "${N8N_SMTP_CREDENTIAL_ID:-}" ]]; then
  info "Patching workflows..."

  RECV_OUT="$SCRIPT_DIR/workflows/docmail-receiver.local.json"
  sed \
    -e "s|/home/node/docmail|${N8N_DOCMAIL_DIR}|g" \
    -e "s|YOUR_SMTP_CREDENTIAL_ID|${N8N_SMTP_CREDENTIAL_ID}|g" \
    -e "s|\"SMTP account\"|\"${N8N_SMTP_CREDENTIAL_NAME:-SMTP account}\"|g" \
    -e "s|Europe/Paris|${DOCMAIL_TIMEZONE:-Europe/Paris}|g" \
    "$SCRIPT_DIR/workflows/docmail-receiver.json" > "$RECV_OUT"
  ok "Patched → workflows/docmail-receiver.local.json"

  RECAP_OUT="$SCRIPT_DIR/workflows/docmail-morning-recap.local.json"
  sed \
    -e "s|/home/node/docmail|${N8N_DOCMAIL_DIR}|g" \
    -e "s|YOUR_SMTP_CREDENTIAL_ID|${N8N_SMTP_CREDENTIAL_ID}|g" \
    -e "s|\"SMTP account\"|\"${N8N_SMTP_CREDENTIAL_NAME:-SMTP account}\"|g" \
    -e "s|Europe/Paris|${DOCMAIL_TIMEZONE:-Europe/Paris}|g" \
    -e "s|\"triggerAtHour\": 8|\"triggerAtHour\": ${DOCMAIL_RECAP_HOUR:-8}|g" \
    "$SCRIPT_DIR/workflows/docmail-morning-recap.json" > "$RECAP_OUT"
  ok "Patched → workflows/docmail-morning-recap.local.json"
else
  warn "N8N_DOCMAIL_DIR / N8N_SMTP_CREDENTIAL_ID not set — skipping n8n workflow patching."
  warn "Fine if you route through something other than the bundled n8n workflows."
  RECV_OUT="(skipped)"
  RECAP_OUT="(skipped)"
fi

# ── Step 8: Install skill to Claude Code ────
CLAUDE_SKILL_DIR="$HOME/.claude/skills/docmail"
info "Installing skill to $CLAUDE_SKILL_DIR"

mkdir -p "$CLAUDE_SKILL_DIR/references" "$CLAUDE_SKILL_DIR/scripts"
cp "$SKILL_OUT" "$CLAUDE_SKILL_DIR/SKILL.md"
cp "$SCRIPT_DIR"/skill/references/*.md "$CLAUDE_SKILL_DIR/references/"
cp "$SCRIPT_DIR"/skill/scripts/*.sh "$CLAUDE_SKILL_DIR/scripts/"
chmod +x "$CLAUDE_SKILL_DIR"/scripts/*.sh
# Normalize line endings in case the repo was checked out with CRLF
sed -i 's/\r$//' "$CLAUDE_SKILL_DIR"/scripts/*.sh 2>/dev/null || true
ok "Skill installed → $CLAUDE_SKILL_DIR/ (SKILL.md + references/ + scripts/)"

# ── Done ─────────────────────────────────────
echo ""
echo "─────────────────────────────────────────"
echo -e "${GREEN}${BOLD}Installation complete!${NC}"
echo "─────────────────────────────────────────"
echo ""
echo "What was done:"
echo "  [x] Config validated"
echo "  [x] queue/ sent/ failed/ created under $DOCMAIL_HOME"
echo "  [x] Auth token ready"
echo "  [x] Skill + references + scripts installed to Claude Code"
echo "  [x] n8n workflows: $RECV_OUT"
echo ""
echo -e "${BOLD}Remaining manual steps (webhook server):${NC}"
echo ""
echo "  1. If you use n8n, import the patched workflows (Settings > Import):"
echo "     - $RECV_OUT"
echo "     - $RECAP_OUT"
echo ""
echo "  2. Set server environment variables:"
echo "     - DOCMAIL_TOKEN = contents of $TOKEN_FILE"
echo "     - SMTP_USER    = your email address"
echo ""
echo "  3. Create the server storage directory (n8n):"
echo "     mkdir -p ${N8N_DOCMAIL_DIR:-/home/node/docmail}/archive"
echo ""
echo "  4. Activate both workflows"
echo ""
echo "  5. Test from Claude Code:"
echo "     /docmail now test installation"
echo ""
