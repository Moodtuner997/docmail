---
name: docmail
description: "Generates a newsletter-format HTML email (6-section standard) and routes it through a secure webhook with secret scanning. Triggers: user says /docmail, /docmail now, /docmail arbitrage, or asks to 'generate a doc for email', 'session recap email'. Modes: instant, batch (morning cron), arbitrage snapshot."
user-invocable: true
allowed-tools: Read, Write, Bash, Glob, Grep
---

# Docmail — Generate and Send Documents

Generate ONE HTML document. Save it to the queue. Send it through `scripts/send-webhook.sh`.

Email = readable newsletter + HTML attachment. Max 1 document per invocation.

## Configuration

All runtime values come from your config file (`~/docmail.conf` by default, see `docmail.conf.example`).
Never hardcode secrets in documents or scripts.

| Key | Type | Usage |
|---|---|---|
| `DOCMAIL_HOME` | config | Base directory. Contains `queue/`, `sent/`, `failed/` |
| `DOCMAIL_WEBHOOK_URL` | config / env var | Full POST endpoint of your webhook (e.g. `https://YOUR_HOST/webhook/docmail`) |
| `DOCMAIL_TOKEN` | env var / secrets file | Bearer token expected by the webhook. Loaded from `$DOCMAIL_SECRETS_DIR/DOCMAIL_TOKEN` (never committed, never displayed) |

**Document lifecycle:**
- `<YOUR_DOCMAIL_HOME>/queue/` — HTML files waiting to be sent
- `<YOUR_DOCMAIL_HOME>/sent/` — confirmed sent (HTTP 2xx) + `.sent` marker
- `<YOUR_DOCMAIL_HOME>/failed/` — blocked (secret detected) or failed (non-2xx) + logs

**Behavior per mode:**
- `instant` / `arbitrage` — immediate send via `scripts/send-webhook.sh`. The email arrives within a minute.
- `batch` — file dropped in `queue/`, sent as a bundle by the next morning cron (see README, "Morning recap").

## Arguments

Strict positional parsing. Word 1 is the ONLY candidate for MODE. Word 2 is the ONLY
candidate for VOICE. Everything else = INSTRUCTIONS (even if it contains "now" or a voice name).

1. `$1` == `now` exactly -> MODE=instant ; `$1` == `arbitrage` exactly -> MODE=arbitrage ; otherwise MODE=batch (and `$1` is part of INSTRUCTIONS).
2. If MODE != batch AND `$2` is in the voice table below -> VOICE=$2, INSTRUCTIONS=`$3..$n`.
3. Otherwise INSTRUCTIONS=`$2..$n` (or `$1..$n` if MODE=batch).

| Example | Mode | Voice | Instructions |
|---|---|---|---|
| `/docmail session recap` | batch | — | "session recap" |
| `/docmail now project summary` | instant | — | "project summary" |
| `/docmail now tommy sprint plan` | instant | tommy | "sprint plan" |
| `/docmail now tony now` | instant | tony | "now" (2nd "now" = content) |
| `/docmail arbitrage` | arbitrage | — | current conversation |

## Voices (optional)

Optional extra definitions: `<YOUR_VOICE_DEFINITIONS_PATH>` (leave unset to use the table below only).

The voice applies to PROSE SECTIONS only (intro, transitions, conclusion). Never to data, tables or facts.

| Word | Personality | Style |
|---|---|---|
| `tony` | Tony Soprano | "Listen to me", family org chart, boss briefing |
| `arthur` | Arthur Pendragon (Kaamelott) | Exasperated king, demystification |
| `walter` | Walter White | Precision, zero approximation |
| `gandalf` | Gandalf | Patience, long-term, wisdom |
| `papacito` | Papacito | "The basics.", direct coach |
| `tommy` | Tommy Shelby | "Here's what we do", cold orders |
| `geralt` | Geralt of Rivia | "Hmm.", laconic pragmatism |
| `luffy` | Luffy | "OI!", enthusiasm, adventure |

If no voice matches, treat the word as INSTRUCTIONS.

### Voice rules
- Intro: in character (1-3 sentences)
- Transitions: light touches of the character's vocabulary
- Conclusion: back in character
- Data/tables: neutral, never in character
- If the voice feels forced on the content -> write naturally
- If VOICE is set, add a footer note: `Written in [personality] mode`

---

## ARBITRAGE mode

When `MODE=arbitrage`, the document is a decision snapshot of the current conversation:

1. **Review the conversation** for decisions that were made. For each decision, classify it:
   - **Verified** — backed by a test, a diff, a log, a measurement
   - **Assumed** — treated as true without evidence ("it should work", "it's always like that")
2. **Capture the output**: decisions detected, classification, recommendations (which assumptions to verify first).
3. **Generate the docmail** with the standard format (see references/), content = the snapshot.
4. **Subject** = "Arbitrage — [project or context]".

If you have a dedicated decision-review skill installed, invoke it instead of the manual checklist and capture its output.

This turns an ephemeral decision analysis into a persistent document.

---

## Format and design system

**MANDATORY — read BEFORE generating the HTML:**

- `references/format-standard.md` — the 6-section structure every docmail must follow
- `references/design-system.md` — the exact classes and colors. Do not reinvent styles.

**Key reminders:**
- Inline CSS only, zero external dependencies (no CDN, no Google Fonts)
- `max-width: 480px` (mobile-first)
- HTML entities for accented characters (`&eacute;` not `é`)
- `box-sizing: border-box` on `*`
- Background `#f0f4f8` (ice), accent `#e05848` (coral), cards `#fff`, borders `#d0dce8`
- h1 headings: `Georgia, serif`. Body: `-apple-system, sans-serif`
- Section labels: uppercase, `letter-spacing: 1.5px`, coral

---

## Step 1 — Generate the HTML

1. Scan the LAST 40 TURNS of conversation maximum (not the whole session — costly and dilutes the signal). If the user asks for a broader recap, scan up to 80 turns.
2. If a project is identifiable and you keep per-project context notes, read them for the timeless recap section.
3. Generate the HTML with the standard format (`references/format-standard.md`) + design system.
4. The HTML must be readable as an email body AND as an attachment:
   - Inline CSS only, no base64 images unless explicitly requested
   - Tables for layout if divs break in email clients

## Step 2 — Name and save

Convention: `docmail_<theme>_<context>_<DDMMYY>.html`
- theme: 1 word (synthesis, recap, arbitrage, todos, onesheet, specs, notes)
- context: 1 word for the project/subject
- DDMMYY: today's date

Save to: `<YOUR_DOCMAIL_HOME>/queue/<filename>` (always `queue/`, never the base directory).
After a confirmed 2xx, `send-webhook.sh` moves the file to `sent/` and creates the `.sent` marker.
Readable state at any time: `ls queue/` -> waiting ; `ls sent/` -> delivered to the webhook.

## Step 3 — Send or queue

```bash
bash ~/.claude/skills/docmail/scripts/send-webhook.sh "<filename.html>" "<instant|batch>" "[Docmail] <subject>"
```

**The MODE (argument 2) is MANDATORY.** Without it the script silently defaults to `batch`
and the email only leaves at the next morning cron — while the user expected a `now`.
`MODE=instant` or `arbitrage` -> pass `"instant"`.

The script scans for secrets, parses the HTTP status, and only creates the `.sent` marker
after a confirmed 2xx. After sending: **remember that 2xx = the webhook received the POST,
not proof the email was delivered.** Check the inbox before declaring "sent".

> **Argument 1 = FILENAME ONLY** (e.g. `docmail_recap_myproject_210726.html`), never the full
> path: the script prefixes `queue/` itself. Passing an absolute path doubles the prefix -> "file not found".

Confirm to the user based on exit code:
- `0` -> "Document sent (instant)." or "Document queued for the morning recap." (batch)
- `1` -> "BLOCKED: secret detected in the document. File moved to failed/. Fix and retry."
- `2` -> "Webhook failed (non-2xx). File stays in queue/ and will be retried by the next cron."

### If MODE=batch

The file stays in `queue/`; the morning cron calls `send-webhook.sh` for each `.html`.
Confirm: "Document waiting in queue/. It will be sent in the morning recap."

---

## Rules

- **NEVER** include sensitive data (API keys, tokens, passwords, private key paths, secret-store paths)
- **ALWAYS** the standard format (the 6 sections). No exceptions.
- **ALWAYS** inline CSS — zero CDN, zero Google Fonts
- **NEVER** create a `.sent` marker manually — only the script does, on confirmed 2xx
- Filenames: lowercase, underscores, no spaces
- One document per invocation
- If the instructions mention a session/conversation -> scan the conversation context
