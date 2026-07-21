# Docmail v2 — Design System Reference

> Swiss Arctic + Coral accent. Inline CSS only. No CDN, no external fonts. Optimized for modern smartphones (480px).

## Foundations

```html
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

- Accented characters: HTML entities (`&eacute;`, `&agrave;`, `&ccedil;`, `&ocirc;`, `&egrave;`, `&ucirc;`, `&icirc;`, `&euml;`) — never raw UTF-8
- `box-sizing: border-box` on `*`
- `@media print { body { background: #fff; max-width: 100%; } .card { break-inside: avoid; } h2 { break-after: avoid; } }`

## Layout

```css
body { max-width: 480px; margin: 0 auto; padding: 16px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; font-size: 15px; line-height: 1.6; color: #1a2a3a; background: #f0f4f8; }
```

## Typography

```css
h1 { font-family: Georgia, 'Times New Roman', serif; font-size: 22px; font-weight: 700; color: #1a2a3a; margin-bottom: 4px; }
h2 { font-size: 17px; font-weight: 700; color: #e05848; margin-top: 28px; border-bottom: 1px solid #d0dce8; padding-bottom: 6px; margin-bottom: 12px; }
h3 { font-size: 15px; font-weight: 600; color: #1a2a3a; margin-bottom: 6px; }
.subtitle { font-size: 13px; color: #6b8299; border-bottom: 2px solid #e05848; padding-bottom: 12px; margin-bottom: 20px; }
.section-label { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 1.5px; color: #e05848; margin-bottom: 6px; }
```

## Colors

| Token | Value | Usage |
|---|---|---|
| Background | `#f0f4f8` | Body (ice) |
| Text | `#1a2a3a` | Body (cold ink) |
| Accent | `#e05848` | Headings, borders, stat values (coral) |
| Card BG | `#fff` | Cards |
| Border | `#d0dce8` | Dividers, card borders (ice) |
| Subtle | `#6b8299` | Secondary text (steel) |
| Row alt | `#e8eef4` | Table rows |
| Triptych BG | `#fff0ec` | Triptych card background (pale coral) |
| Context BG | `#eff6ff` | Timeless recap background (pale blue) |

## Components

### Cards
```css
.card { background: #fff; border: 1px solid #d0dce8; border-radius: 6px; padding: 14px; margin-bottom: 12px; }
.card-accent { border-left: 4px solid #e05848; }
.card-context { border-left: 4px solid #2563eb; background: #eff6ff; }
.card-green { border-left: 4px solid #2d8a4e; }
.card-orange { border-left: 4px solid #d97706; }
```

### Labels
```css
.label { display: inline-block; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; padding: 2px 8px; border-radius: 4px; margin-bottom: 6px; }
.label-coral { background: #fff0ec; color: #b83a2e; }
.label-green { background: #dcfce7; color: #166534; }
.label-blue { background: #dbeafe; color: #1e40af; }
.label-orange { background: #fef3c7; color: #92400e; }
.label-red { background: #fee2e2; color: #991b1b; }
.label-gray { background: #e8eef4; color: #3a4a5a; }
```

### Stat Grid
```css
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.stat { text-align: center; padding: 10px; }
.stat-value { font-size: 24px; font-weight: 700; color: #e05848; }
.stat-label { font-size: 10px; color: #6b8299; text-transform: uppercase; letter-spacing: 0.5px; }
```

### Tables
```css
table { width: 100%; border-collapse: collapse; font-size: 13px; margin-bottom: 10px; }
th { text-align: left; font-weight: 700; color: #6b8299; font-size: 10px; text-transform: uppercase; letter-spacing: 1px; padding: 6px 8px; border-bottom: 2px solid #d0dce8; }
td { padding: 8px; border-bottom: 1px solid #e8eef4; vertical-align: top; }
```

### Timeline
```css
.timeline-item { padding-left: 20px; border-left: 2px solid #d0dce8; margin-bottom: 10px; position: relative; }
.timeline-item::before { content: ''; position: absolute; left: -5px; top: 8px; width: 8px; height: 8px; border-radius: 50%; background: #e05848; }
.timeline-time { font-size: 13px; font-weight: 600; color: #e05848; }
.timeline-text { font-size: 13px; color: #3a4a5a; }
```

### Flow Steps
```css
.flow-step { display: flex; align-items: flex-start; margin-bottom: 8px; }
.flow-icon { flex-shrink: 0; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; margin-right: 10px; background: #e8eef4; color: #1a2a3a; font-weight: 700; }
.flow-text { flex: 1; font-size: 14px; padding-top: 4px; }
.flow-arrow { text-align: center; color: #e05848; font-size: 18px; margin: 2px 0 2px 11px; }
```

### Mono
```css
.mono { font-family: 'SF Mono', Consolas, Monaco, monospace; font-size: 12px; background: #e8eef4; padding: 1px 5px; border-radius: 3px; color: #1a2a3a; }
```

### Section Note / Timestamp
```css
.section-note { font-size: 12px; color: #6b8299; font-style: italic; margin-top: 6px; }
.horodatage { font-size: 11px; color: #6b8299; font-style: italic; padding: 8px 0; border-top: 1px solid #d0dce8; border-bottom: 1px solid #d0dce8; margin-bottom: 14px; }
```

### Footer
```css
footer { margin-top: 32px; padding-top: 16px; border-top: 2px solid #d0dce8; font-size: 11px; color: #8a9ab0; text-align: center; }
```

## Component Selection Guide

Pick components based on content type — don't use all of them:

| Content type | Component |
|---|---|
| Numbers/KPIs | stat grid |
| Status/state | labels inside cards |
| Chronological | timeline |
| Step-by-step | flow steps |
| Data rows | tables |
| Key info blocks | cards (accent color = importance) |
| Technical values | mono spans |
| Section headers in triptych/recap | `.section-label` (uppercase, letter-spacing, coral) |
