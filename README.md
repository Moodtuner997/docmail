# docmail

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Made for Claude Code](https://img.shields.io/badge/Made%20for-Claude%20Code-d97757.svg)](https://docs.anthropic.com/en/docs/claude-code)

Personal document-to-email pipeline powered by Claude Code.

Type `/docmail session recap` in your terminal, get a beautiful newsletter-style HTML email in your inbox — instantly, or bundled into a morning recap. Every document goes through a secret scan before it leaves your machine.

## How it works

```
Claude Code (terminal)
  └─ /docmail now "session recap"
       ├─ Generate styled HTML document (6-section newsletter format)
       ├─ Save to queue/
       └─ send-webhook.sh
            ├─ scan-secrets.sh  → BLOCK if API key / token / private key found
            ├─ POST to your webhook (Bearer token)
            └─ 2xx confirmed → move to sent/
                 └─ Your router (n8n workflows bundled)
                      ├─ mode=instant → Email immediately + archive
                      └─ mode=batch   → Save to server queue
                                           └─ Morning cron → Email all queued as one recap
```

**Components:**
- **Skill** (`skill/SKILL.md` + `references/` + `scripts/`) — Claude Code skill: generates the doc, scans it, sends it
- **Receiver workflow** (`workflows/docmail-receiver.json`) — n8n workflow that receives documents and emails them
- **Recap workflow** (`workflows/docmail-morning-recap.json`) — n8n cron that bundles queued documents into a morning email

n8n is the reference router, but anything that accepts the JSON POST works (Node-RED, a tiny Flask/Express app, a serverless function...).

## Features

- **6-section newsletter format** — header, timeless context recap, problem/reasoning/solutions triptych, timestamp, content, technical signature
- **Design system v2** — "Swiss Arctic + coral": ice background, serif headings, 10 reusable components (cards, labels, stat grids, tables, timelines, flow steps...), inline CSS only, renders offline and in email clients, mobile-first 480px
- **3 modes** — `instant` (email in a minute), `batch` (morning recap bundle), `arbitrage` (decision snapshot: which decisions this session were verified vs. assumed)
- **Secret scanning before every send** — API keys, JWTs, private keys, cloud credentials block the send; the file is quarantined in `failed/`
- **Honest document lifecycle** — `queue/` → `sent/` only after a confirmed HTTP 2xx; failures keep the file in `queue/` for automatic retry
- **8 optional voice personalities** — Tony Soprano, Gandalf, Geralt, Tommy Shelby... (prose only, never the data)
- **Hardened sender** — Bearer token auth, curl retries, DNS-cache auto-recovery on Windows, "2xx received ≠ email delivered" guard
- **Secure receiver** — path traversal protection + 5MB payload limit in the bundled n8n workflows

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- A webhook-reachable email router — the bundled [n8n](https://n8n.io/) workflows need a self-hosted n8n with SMTP credentials, reachable over LAN, VPN or HTTPS
- `openssl` (token generation), `curl`, and `jq` *or* `python3` (JSON payload)

## Install

```bash
# 1. Clone
git clone https://github.com/Moodtuner997/docmail.git
cd docmail

# 2. Create your config (copies the template to ~/docmail.conf)
bash install.sh --init
nano ~/docmail.conf   # fill in your values

# 3. Run the installer
bash install.sh
```

The installer will:
- Validate your config (catches placeholder values left unchanged)
- Create `queue/`, `sent/`, `failed/` under your `DOCMAIL_HOME`
- Generate an auth token (if none exists)
- Install the skill + references + scripts into `~/.claude/skills/docmail/`
- Patch the n8n workflows with your paths (if configured)

Then set up the webhook side (the installer prints the exact steps) and send your first docmail:

```
/docmail now test installation
```

You should receive an email titled `[Docmail] test installation` within a minute.

### WSL / Git Bash note

If you get `\r` errors, fix line endings first:

```bash
sed -i 's/\r$//' install.sh skill/scripts/*.sh
bash install.sh
```

## Configuration

All config lives in `~/docmail.conf` (or wherever `$DOCMAIL_CONF` points). See [`docmail.conf.example`](docmail.conf.example) for all options.

| Variable | Required | Description |
|---|---|---|
| `DOCMAIL_HOME` | Yes | Base directory — the installer creates `queue/`, `sent/`, `failed/` inside |
| `DOCMAIL_SECRETS_DIR` | Yes | Directory containing the `DOCMAIL_TOKEN` file |
| `DOCMAIL_WEBHOOK_URL` | Yes | Full URL of your webhook endpoint |
| `N8N_DOCMAIL_DIR` | If using n8n | Path on the n8n server where documents are stored |
| `N8N_SMTP_CREDENTIAL_ID` | If using n8n | n8n SMTP credential ID (Settings > Credentials) |
| `DOCMAIL_VOICE_DEFS` | No | Extra voice personality definitions |
| `DOCMAIL_TIMEZONE` | No | Timezone for recap cron (default: `Europe/Paris`) |
| `DOCMAIL_RECAP_HOUR` | No | Hour for morning recap (default: `8`) |

## Usage

From Claude Code:

```
/docmail session recap                 # batch mode, sent with the morning recap
/docmail now project summary           # instant email
/docmail arbitrage                     # decision snapshot of the conversation
/docmail now tony session recap        # instant + Tony Soprano voice
```

### Document lifecycle

```
queue/    HTML files waiting to be sent (batch, or failed sends awaiting retry)
sent/     confirmed sent (HTTP 2xx) + .sent marker — created by the script only
failed/   secret detected (quarantined) or HTTP error logs
```

The morning cron simply re-runs the sender on everything in `queue/` — failed sends retry themselves daily with zero effort.

## Design system

The generated HTML uses a self-contained design system optimized for email ([full reference](skill/references/design-system.md), [live example](examples/example-docmail.html)):

- **Colors:** ice background (`#f0f4f8`), coral accent (`#e05848`), cold ink text
- **Typography:** serif display headings (Georgia), system fonts for body, uppercase section labels
- **Components:** cards, labels, stat grids, tables, timelines, flow steps, mono spans...
- **Layout:** 480px max-width, mobile-first, print-friendly

Open [`examples/example-docmail.html`](examples/example-docmail.html) in a browser to see a full 6-section docmail.

## Security

- **Secret scan before every send** — known API key formats (OpenAI, Anthropic, GitHub, AWS, Google, Slack, GitLab, Hugging Face), JWTs, private key blocks and sensitive paths block the send and quarantine the file
- Webhook protected by Bearer token (stored outside the repo, `chmod 600`)
- Payload size capped at 5MB, filename sanitization + path traversal rejection on the receiver
- `.sent` markers are only ever created by the script, after a confirmed 2xx — no silent drops
- Config file permissions: `600` (owner-only read/write)

## FAQ / Troubleshooting

**My "now" email only arrived the next morning.**
The mode argument was omitted — the sender defaults to `batch`. Always pass `"instant"` as the 2nd argument of `send-webhook.sh` (the skill does this when you say `/docmail now`).

**The script says OK 200 but no email arrived.**
2xx means your webhook *received* the POST, not that the email was delivered. Check the router's execution logs (n8n: Executions tab) and your SMTP credentials.

**`file not found` when sending manually.**
Pass the *filename only* (`docmail_recap_myproject_210726.html`), not the full path — the script prefixes `queue/` itself.

**HTTP 000 on Windows.**
Usually a stale negative DNS cache entry. The script flushes it and retries once automatically; if it persists, check that your webhook host resolves (`nslookup your-host`).

**HTTP 401/403.**
Token mismatch. Compare the token file contents with the `DOCMAIL_TOKEN` env var on the webhook server (and restart the server after changing it).

**A file has been stuck in `queue/` for days.**
Failed sends retry daily, forever — there is no automatic cap. Check `failed/` for the HTTP logs, fix the cause, or remove the file.

## File structure

```
docmail/
├── install.sh                       # One-command installer
├── docmail.conf.example             # Config template (committed)
├── skill/
│   ├── SKILL.md                     # Claude Code skill (generic)
│   ├── references/
│   │   ├── design-system.md         # v2 design system (colors, components)
│   │   └── format-standard.md       # the mandatory 6-section format
│   └── scripts/
│       ├── scan-secrets.sh          # blocks sends containing secrets
│       └── send-webhook.sh          # queue → scan → POST → sent/
├── examples/
│   └── example-docmail.html         # anonymized sample email
└── workflows/
    ├── docmail-receiver.json        # n8n: webhook → email/queue
    └── docmail-morning-recap.json   # n8n: cron → batch email
```

After running `install.sh`:
- `skill/SKILL.local.md` and `workflows/*.local.json` are generated (gitignored)
- The skill is copied to `~/.claude/skills/docmail/` (SKILL.md + references + scripts)
- A token is generated in your secrets directory

## Updating

After a `git pull`, re-run `bash install.sh` to re-patch files with any upstream changes. Your `~/docmail.conf` and token are untouched.

**Upgrading from v1:** replace `DOCMAIL_OUTPUT_DIR` with `DOCMAIL_HOME` in your config (the installer will tell you), and set `DOCMAIL_WEBHOOK_URL` to the *full* endpoint URL (including `/webhook/docmail`). Existing HTML files can be moved into `$DOCMAIL_HOME/queue/`.

## License

[MIT](LICENSE)
