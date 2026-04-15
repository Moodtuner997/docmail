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
- A webhook-reachable n8n server (LAN, VPN, or public with HTTPS)
- `openssl` (for token generation — installed on most systems)

## Install

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/docmail.git
cd docmail

# 2. Create your config (copies the template to ~/docmail.conf)
bash install.sh --init

# 3. Edit with your values
nano ~/docmail.conf

# 4. Run the installer
bash install.sh
```

The installer will:
- Validate your config (catches placeholder values left unchanged)
- Create local directories (output + secrets)
- Generate an auth token (if none exists)
- Patch all placeholders with your values
- Install the skill directly into `~/.claude/skills/docmail/`

After that, you just need to set up the n8n side (the installer prints the exact steps).

### WSL / Git Bash note

If you get `\r` errors, fix line endings first:

```bash
sed -i 's/\r$//' install.sh
bash install.sh
```

## Configuration

All config lives in `~/docmail.conf` (or wherever `$DOCMAIL_CONF` points). See [`docmail.conf.example`](docmail.conf.example) for all options.

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
- Config file permissions: `600` (owner-only read/write)

## File structure

```
docmail/
├── install.sh                    # One-command installer
├── docmail.conf.example          # Config template (committed)
├── skill/
│   └── SKILL.md                  # Claude Code skill (generic)
└── workflows/
    ├── docmail-receiver.json     # n8n: webhook → email/queue
    └── docmail-morning-recap.json # n8n: cron → batch email
```

After running `install.sh`:
- `skill/SKILL.local.md` and `workflows/*.local.json` are generated (gitignored)
- The skill is copied to `~/.claude/skills/docmail/SKILL.md`
- A token is generated in your secrets directory

## Updating

After a `git pull`, re-run `bash install.sh` to re-patch files with any upstream changes. Your `~/docmail.conf` and token are untouched.

## License

[MIT](LICENSE)
