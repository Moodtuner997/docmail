---
name: docmail
description: "Use when user says /docmail or asks to generate a document for email. Supports batch (morning 8h) and instant modes."
user-invocable: true
allowed-tools: Read, Write, Bash, Glob
---

# Docmail — Generate and Send Documents

## Arguments

Parse the user's arguments in order:
1. If the first word is `now`, set MODE=instant, consume it
2. If the next word matches a VOICE name (see below), set VOICE=that name, consume it
3. Rest of args = INSTRUCTIONS

Examples:
- `/docmail recap session` → batch, no voice, "recap session"
- `/docmail now synthese moodtune` → instant, no voice, "synthese moodtune"
- `/docmail tony recap session` → batch, voice=Tony Soprano, "recap session"
- `/docmail now gandalf synthese projet` → instant, voice=Gandalf, "synthese projet"

## Voices (optional)

Reference: `<YOUR_VOICE_DEFINITIONS_PATH>/voix-explicatives.md`

If VOICE is set, the document content adopts the personality's tone and formulations while keeping the information factual. The voice applies to PROSE SECTIONS only (intros, summaries, commentary) — not to data tables, lists of facts, or technical specs.

| Trigger word | Personality | Style |
|---|---|---|
| `tony` | Tony Soprano | Boss qui brief. "Ecoute-moi bien", "Capisce?", organigramme familial |
| `arthur` | Arthur Pendragon (Kaamelott) | Roi exaspere. "C'est pas POSSIBLE", demystification, medievalisme |
| `walter` | Walter White | Chimiste obsede. "Laisse-moi t'expliquer", precision, zero approximation |
| `gandalf` | Gandalf | Sage perspectif. "Des forces sont en mouvement", patience, long-terme |
| `papacito` | Papacito | Coach direct. "La base.", "Le mec qui...", programme muscu |
| `tommy` | Tommy Shelby | Stratege froid. "Here's what we do", ordres, pas de questions |
| `geralt` | Geralt de Riv | Pragmatique laconique. "Hmm.", "Le moindre mal", phrases courtes |
| `luffy` | Luffy | Enthousiaste pur. "OI!", "On y va!", aventure, viande |

If no voice matches, ignore and treat the word as part of INSTRUCTIONS.

### Voice application rules
- Intro paragraph: fully in character (1-3 phrases)
- Section transitions: light touches of the character's lexique
- Conclusions: back in character for the closing
- Data/facts/tables: neutral, no character embellishment
- If the voice feels forced on the content, drop it and write naturally

## Step 1 — Generate the document

Based on INSTRUCTIONS (and optional VOICE), generate a self-contained HTML document following the design system below.

### Foundations
- Inline CSS only (no external stylesheets, no CDN fonts)
- NO external dependencies — renders perfectly offline and as email attachment
- `<meta charset="UTF-8">` + `<meta name="viewport" content="width=device-width, initial-scale=1.0">`
- Accented characters: use HTML entities (`&eacute;`, `&agrave;`, `&ccedil;`, `&ocirc;`, `&egrave;`, `&ucirc;`, `&icirc;`, `&euml;`) — never raw UTF-8 accents
- If VOICE is set, add a subtle footer note: `Redige en mode [personality name]`

### Layout
- `max-width: 480px; margin: 0 auto; padding: 16px` (mobile-first, optimized for modern smartphones)
- `box-sizing: border-box` on `*`
- `@media print { body { background: #fff; max-width: 100%; } .card { break-inside: avoid; } h2 { break-after: avoid; } }`

### Typography
- Font stack: `-apple-system, BlinkMacSystemFont, Roboto, Arial, sans-serif` (body AND headings)
- Body: `font-size: 15px; line-height: 1.6; color: #1a1a1a`
- h1: `22px, weight 700, margin-bottom 4px`
- h2: `17px, weight 700, color #a34338, margin-top 28px, border-bottom 1px solid #e0ddd8`
- h3: `15px, weight 600, color #333`
- `.subtitle`: `13px, color #666, border-bottom 2px solid #a34338` (below h1)

### Colors
- Background: `#faf9f6` (cream)
- Text: `#1a1a1a`
- Accent: `#a34338` (terracotta) — headings, borders, stat values
- Cards: `#fff` background, `1px solid #e0ddd8` border, `border-radius: 10px`, `padding: 14px`
- Subtle text: `#666`
- Dividers: `#e0ddd8` (light) / `#f0eeea` (table rows)

### Components (use as needed based on content)

**Cards** — Primary content container
```css
.card { background: #fff; border: 1px solid #e0ddd8; border-radius: 10px; padding: 14px; margin-bottom: 12px; }
.card-accent { border-left: 4px solid #a34338; }  /* important/primary */
.card-green { border-left: 4px solid #2d8a4e; }   /* success/active */
.card-blue { border-left: 4px solid #2563eb; }     /* info/secondary */
.card-orange { border-left: 4px solid #d97706; }   /* warning/pending */
```

**Labels** — Status badges inline
```css
.label { display: inline-block; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; padding: 2px 8px; border-radius: 4px; margin-bottom: 6px; }
.label-green { background: #dcfce7; color: #166534; }   /* done/active/ok */
.label-blue { background: #dbeafe; color: #1e40af; }     /* info */
.label-orange { background: #fef3c7; color: #92400e; }   /* in progress */
.label-red { background: #fee2e2; color: #991b1b; }       /* error/critical */
.label-gray { background: #f3f4f6; color: #374151; }      /* pending/neutral */
```

**Stat grid** — Key numbers (2 columns)
```css
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.stat { text-align: center; padding: 10px; }
.stat-value { font-size: 24px; font-weight: 700; color: #a34338; }
.stat-label { font-size: 11px; color: #666; text-transform: uppercase; letter-spacing: 0.3px; }
```

**Tables** — Data display
```css
table { width: 100%; border-collapse: collapse; font-size: 13px; margin-bottom: 10px; }
th { text-align: left; font-weight: 600; color: #666; font-size: 11px; text-transform: uppercase; letter-spacing: 0.3px; padding: 6px 8px; border-bottom: 2px solid #e0ddd8; }
td { padding: 8px; border-bottom: 1px solid #f0eeea; vertical-align: top; }
```

**Timeline** — Chronological items
```css
.timeline-item { padding-left: 20px; border-left: 2px solid #e0ddd8; margin-bottom: 10px; position: relative; }
.timeline-item::before { content: ''; position: absolute; left: -5px; top: 8px; width: 8px; height: 8px; border-radius: 50%; background: #a34338; }
.timeline-time { font-size: 13px; font-weight: 600; color: #a34338; }
.timeline-text { font-size: 13px; color: #444; }
```

**Flow steps** — Sequential process
```css
.flow-step { display: flex; align-items: flex-start; margin-bottom: 8px; }
.flow-icon { flex-shrink: 0; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; margin-right: 10px; background: #f3f2ef; }
.flow-text { flex: 1; font-size: 14px; padding-top: 4px; }
.flow-arrow { text-align: center; color: #a34338; font-size: 18px; margin: 2px 0 2px 11px; }
```

**Access rows** — Permission display
```css
.access-row { display: flex; justify-content: space-between; align-items: center; padding: 8px 0; border-bottom: 1px solid #f0eeea; font-size: 13px; }
.access-badge { font-size: 11px; font-weight: 600; padding: 2px 6px; border-radius: 3px; }
.access-public { background: #fee2e2; color: #991b1b; }
.access-private { background: #dcfce7; color: #166534; }
.access-blocked { background: #f3f4f6; color: #374151; }
```

**Mono** — Code/technical values inline
```css
.mono { font-family: 'SF Mono', Consolas, Monaco, monospace; font-size: 12px; background: #f3f2ef; padding: 1px 5px; border-radius: 3px; }
```

**Section note** — Subtle footnote under a card
```css
.section-note { font-size: 12px; color: #888; font-style: italic; margin-top: 6px; }
```

**Footer**
```css
footer { margin-top: 32px; padding-top: 16px; border-top: 2px solid #e0ddd8; font-size: 11px; color: #999; text-align: center; }
```

### Component selection guide
Pick components based on content type — don't use all of them:
- **Numbers/KPIs** → stat grid
- **Status/state** → labels inside cards
- **Chronological events** → timeline
- **Step-by-step process** → flow steps
- **Data rows** → tables
- **Permissions/access** → access rows
- **Key info blocks** → cards (with accent color matching importance)
- **Technical values** → mono spans

## Step 2 — Name and save

Convention: `docmail_<theme>_<context>_<DDMMYY>.html`
- theme: 1 word describing the type (synthese, todos, onesheet, recap, specs, notes)
- context: 1 word for the project or subject
- DDMMYY: today's date

Save to: `<YOUR_DOCMAIL_OUTPUT_DIR>/<filename>`

Use the Write tool to create the file.

## Step 3 — Send or queue

### If MODE=instant

1. Read the file content and POST to your webhook as JSON:
```bash
TOKEN=$(cat "<YOUR_SECRETS_DIR>/DOCMAIL_TOKEN" | tr -d '\r\n') && CONTENT=$(cat "<YOUR_DOCMAIL_OUTPUT_DIR>/<filename>" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))") && curl -s -X POST <YOUR_WEBHOOK_URL>/docmail -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "{\"mode\":\"instant\",\"filename\":\"<filename>\",\"subject\":\"<theme> <context>\",\"content\":$CONTENT}"
```

2. Create sent marker:
```bash
touch "<YOUR_DOCMAIL_OUTPUT_DIR>/<filename>.sent"
```

3. Confirm to user: "Document envoye par mail (instantane)."

### If MODE=batch

1. Read the file content and POST to webhook as JSON (same as instant but with mode=batch):
```bash
TOKEN=$(cat "<YOUR_SECRETS_DIR>/DOCMAIL_TOKEN" | tr -d '\r\n') && CONTENT=$(cat "<YOUR_DOCMAIL_OUTPUT_DIR>/<filename>" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))") && curl -s -X POST <YOUR_WEBHOOK_URL>/docmail -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "{\"mode\":\"batch\",\"filename\":\"<filename>\",\"subject\":\"<theme> <context>\",\"content\":$CONTENT}"
```

2. Create sent marker:
```bash
touch "<YOUR_DOCMAIL_OUTPUT_DIR>/<filename>.sent"
```

3. Confirm to user: "Document sauvegarde et uploade sur le VPS. Il sera envoye dans le recap de 8h."

Note: A scheduled task (e.g. daily at 7h) can serve as backup in case the upload fails here.

## Rules

- NEVER include sensitive data (API keys, passwords, tokens, SSH keys) in generated documents
- Always use inline CSS — no CDN, no Google Fonts links
- Keep filenames lowercase, no spaces, underscores only
- One document per invocation
- If the instructions mention a conversation or session, scan the conversation context to extract the relevant information
- The HTML should look good both in a browser and as an email attachment

## Setup Guide

To use this skill, you need to configure the following:
1. **Output directory** — where generated HTML files are saved (replace `<YOUR_DOCMAIL_OUTPUT_DIR>`)
2. **Secrets directory** — where your webhook token is stored (replace `<YOUR_SECRETS_DIR>`)
3. **Webhook URL** — your HTTP endpoint that receives documents (replace `<YOUR_WEBHOOK_URL>`)
4. **Voice definitions** (optional) — a file defining voice personalities (replace `<YOUR_VOICE_DEFINITIONS_PATH>`)
5. **Scheduled sender** (optional) — a cron/task scheduler to send batch documents at a fixed time
