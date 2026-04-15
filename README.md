# docmail

Personal document-to-email pipeline powered by Claude Code and n8n.

Generate styled HTML documents from natural language, send them instantly or batch them into a morning recap email — all from your terminal.

## How it works

```
Claude Code (terminal)
  └─ /docmail "recap session"
       ├─ Generate styled HTML document
       ├─ Save locally
       └─ POST to webhook
            └─ n8n (self-hosted)
                 ├─ mode=instant → Email immediately + archive
                 └─ mode=batch   → Save to queue
                                      └─ Cron 8h → Email all queued as recap + archive
```

**Components:**
- **Skill** (`skill/SKILL.md`) — Claude Code skill that generates HTML docs and sends them via webhook
- **Receiver workflow** (`workflows/docmail-receiver.json`) — n8n workflow that receives documents and emails them
- **Recap workflow** (`workflows/docmail-morning-recap.json`) — n8n cron that bundles queued documents into a morning email

## Features

- Mobile-first HTML design system (480px, inline CSS, works offline and as email attachment)
- 8 optional voice personalities (Tony Soprano, Gandalf, Walter White, etc.)
- Instant send or batch queue with morning recap
- Bearer token auth on the webhook
- Path traversal protection + 5MB payload limit
- Automatic archiving after send

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [n8n](https://n8n.io/) self-hosted instance with SMTP credentials configured
- A machine to generate documents (your dev machine)
- A webhook-reachable n8n server (LAN, VPN, or public with HTTPS)

## Quick start

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/docmail.git
cd docmail

# 2. Configure
cp docmail.conf.example ~/docmail.conf
nano ~/docmail.conf          # Fill in your values
chmod 600 ~/docmail.conf     # Protect credentials

# 3. Generate patched files
bash setup.sh

# 4. Install the skill
mkdir -p ~/.claude/skills/docmail
cp skill/SKILL.local.md ~/.claude/skills/docmail/SKILL.md

# 5. Set up n8n
#    - Import workflows/docmail-receiver.local.json
#    - Import workflows/docmail-morning-recap.local.json
#    - Set env vars: DOCMAIL_TOKEN, SMTP_USER
#    - Create server directory: mkdir -p /your/docmail/dir/archive
#    - Activate both workflows

# 6. Generate your token
openssl rand -hex 32 > ~/path/to/secrets/DOCMAIL_TOKEN
# Set the same value as DOCMAIL_TOKEN env var in n8n

# 7. Test
# In Claude Code:
#   /docmail now test setup
```

## Configuration

See [`docmail.conf.example`](docmail.conf.example) for all options.

| Variable | Required | Description |
|---|---|---|
| `DOCMAIL_OUTPUT_DIR` | Yes | Local directory for generated HTML files |
| `DOCMAIL_SECRETS_DIR` | Yes | Directory containing the `DOCMAIL_TOKEN` file |
| `DOCMAIL_WEBHOOK_URL` | Yes | Your n8n webhook base URL |
| `N8N_DOCMAIL_DIR` | Yes | Path on the n8n server where documents are stored |
| `N8N_SMTP_CREDENTIAL_ID` | Yes | n8n SMTP credential ID (Settings > Credentials) |
| `DOCMAIL_VOICE_DEFS` | No | Path to voice personality definitions |
| `DOCMAIL_TIMEZONE` | No | Timezone for recap cron (default: `Europe/Paris`) |
| `DOCMAIL_RECAP_HOUR` | No | Hour for morning recap (default: `8`) |

## Usage

From Claude Code:

```
/docmail recap session                    # batch mode, sent at 8h
/docmail now synthese projet              # instant email
/docmail tony recap session               # batch + Tony Soprano voice
/docmail now gandalf synthese projet      # instant + Gandalf voice
```

## Design system

The generated HTML uses a self-contained design system optimized for email:

- **Colors:** cream background (`#faf9f6`), terracotta accent (`#a34338`)
- **Components:** cards, labels, stat grids, tables, timelines, flow steps
- **Typography:** system fonts only, no external dependencies
- **Layout:** 480px max-width, mobile-first

## Security

- Webhook protected by Bearer token (stored outside the repo)
- Payload size capped at 5MB
- Filename sanitization + path traversal rejection
- No secrets in generated documents (enforced by skill rules)
- Token file stores bare value only (no `KEY=value` format)

## File structure

```
docmail/
├── docmail.conf.example          # Config template (committed)
├── setup.sh                      # Patches placeholders from config
├── skill/
│   └── SKILL.md                  # Claude Code skill (generic)
└── workflows/
    ├── docmail-receiver.json     # n8n: webhook → email/queue
    └── docmail-morning-recap.json # n8n: cron → batch email
```

After running `setup.sh`, `.local.md` and `.local.json` files are generated with your values (gitignored).

## License

[MIT](LICENSE)
