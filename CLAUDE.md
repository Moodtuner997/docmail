# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Public MIT Claude Code skill: `/docmail` generates a 6-section newsletter-style HTML document, scans it for secrets, and POSTs it to a webhook that emails it (instantly or bundled into a morning recap). Bundled n8n workflows are the reference receiver; any JSON-accepting endpoint works.

## Commands

```bash
bash install.sh --init        # copy docmail.conf.example -> ~/docmail.conf (chmod 600), then edit it
bash install.sh               # validate conf, create queue/sent/failed, generate token, patch + install skill
shellcheck install.sh skill/scripts/*.sh   # lint (scripts already carry `# shellcheck source=/dev/null`)

# manual send / scan (filename only, never a path — the script prefixes queue/ itself)
bash ~/.claude/skills/docmail/scripts/send-webhook.sh docmail_recap_x_010126.html instant "[Docmail] subject"
bash skill/scripts/scan-secrets.sh path/to/file.html      # exit 0 clean, 1 secret, 2 usage error
```

There is no test suite. Manual end-to-end check: `/docmail now test installation` from Claude Code, then confirm the email arrived (a 2xx only means the webhook received the POST).

Deploy of the receiver side: `install.sh` writes `workflows/*.local.json` (patched paths, SMTP credential id, timezone, recap hour); import both into n8n (Settings > Import), set `DOCMAIL_TOKEN` and `SMTP_USER` env vars on the n8n host, `mkdir -p $N8N_DOCMAIL_DIR/archive`, activate both workflows.

## Architecture

- `skill/SKILL.md` is the generic skill source with `<YOUR_DOCMAIL_HOME>` / `<YOUR_VOICE_DEFINITIONS_PATH>` placeholders. `install.sh` seds it into `skill/SKILL.local.md` (gitignored) and copies that to `~/.claude/skills/docmail/SKILL.md` along with `references/` and `scripts/`. Edit `SKILL.md`, never the `.local` copy; re-run `install.sh` after any change.
- `skill/references/format-standard.md` (mandatory 6 sections: header, timeless recap, problem/reasoning/solutions triptych, timestamp, content, technical signature) and `design-system.md` (Swiss Arctic + coral, inline CSS only, 480px, HTML entities for accents). The skill reads both before generating.
- Argument parsing is strictly positional: word 1 is the only MODE candidate (`now` -> instant, `arbitrage`, else batch), word 2 the only VOICE candidate; everything else is instructions.
- Execution flow: generate HTML -> save to `$DOCMAIL_HOME/queue/` -> `send-webhook.sh` runs `scan-secrets.sh` (hard gate; on hit the file moves to `failed/<name>.secret-blocked`, exit 1) -> builds JSON `{mode, filename, subject, content}` with `jq --rawfile` (python3 fallback) -> curl POST with Bearer token, 3 retries, one DNS-flush retry on HTTP 000 when `ipconfig` exists (Windows) -> on 2xx move to `sent/` and touch `.sent` marker (exit 0); otherwise file stays in `queue/`, response logged to `failed/<name>.http-<code>.log` (exit 2). Exit 3 = config/usage error.
- Config precedence: `$DOCMAIL_CONF` (default `~/docmail.conf`) is sourced by both `install.sh` and `send-webhook.sh`; `DOCMAIL_TOKEN` env var wins over `$DOCMAIL_SECRETS_DIR/DOCMAIL_TOKEN` file. Required keys: `DOCMAIL_HOME`, `DOCMAIL_SECRETS_DIR`, `DOCMAIL_WEBHOOK_URL`. The installer rejects placeholder values (`/path/to/`, `example.com`, `your-`) and refuses the legacy key `DOCMAIL_OUTPUT_DIR`.
- n8n side: `docmail-receiver.json` (webhook -> auth check -> instant: save + email + archive / batch: save to server queue) and `docmail-morning-recap.json` (schedule trigger at 8h -> list queued files -> one recap email -> archive). The installer patches `/home/node/docmail`, `YOUR_SMTP_CREDENTIAL_ID`, `"SMTP account"`, `Europe/Paris`, `"triggerAtHour": 8` — keep those literal strings intact in the committed JSON or the sed patching silently stops matching.

## Conventions and gotchas

- Public repo: keep everything user-agnostic. No personal paths, hosts, emails or tokens in committed files; real values live only in `~/docmail.conf` (gitignored via `*.conf`) and `*.local.*` files. `.gitignore` also drops `*.html` except `examples/`.
- Mode argument 2 of `send-webhook.sh` is mandatory in practice: omitting it defaults to `batch` (the script warns on stderr); pass `instant` explicitly, otherwise the email only leaves with the morning cron.
- Never create `.sent` markers by hand; only the script does, after a confirmed 2xx.
- The secret-scan pattern list in `scan-secrets.sh` (OpenAI/Anthropic/GitHub/AWS/Google/Slack/GitLab/HF keys, JWTs, private-key blocks, `.ssh`/`.gnupg` paths) is the safety boundary before anything leaves the machine; extend it there, not in the skill prose.
- Failed sends retry daily forever (the cron re-runs the sender on `queue/`); there is no cap.
- Voice personalities apply to prose only, never to data/tables; add a "Written in X mode" footer when a voice is used.
- Docs are English. Update `README.md` (Configuration table, File structure, FAQ) and `docmail.conf.example` together whenever a config key or script exit code changes.
