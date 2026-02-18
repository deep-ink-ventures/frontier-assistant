---
name: attachment-triage
description: Scores email attachments by importance and suggests Google Drive storage paths. Use when triaging inbox emails with attachments for Drive storage. Triggers on daily briefing, attachment review, or Drive organization tasks.
---

## Attachment Importance Scoring

Score each attachment to decide whether to suggest Drive storage.

### HIGH — Always suggest Drive storage

**Financial documents**:
- Invoices, receipts (PDF/image with "Rechnung", "invoice", "receipt", "Quittung" in filename or email subject)
- Tax documents ("Steuerbescheid", "tax return", "1099", "W-2", "Lohnabrechnung")
- Bank statements ("Kontoauszug", "statement")

**Legal & contracts**:
- Signed documents, contracts ("Vertrag", "contract", "agreement", "Vereinbarung")
- NDAs, terms, amendments
- Official letters from authorities ("Bescheid", "Mitteilung", "Finanzamt")

**Insurance**:
- Policies, claims ("Versicherungsschein", "Police", "policy", "claim")

**Identity & HR**:
- Employment contracts, pay slips ("Arbeitsvertrag", "Gehaltsabrechnung")
- Certificates, diplomas

### MEDIUM — Suggest if from known contact

- Shared documents from real people (not automated)
- Presentations, spreadsheets attached to active project threads
- Meeting notes, agendas
- Design files, specifications

### LOW — Skip (do not suggest)

- Marketing PDFs, brochures, promotional material
- Automated report attachments from SaaS tools (unless explicitly requested)
- Calendar `.ics` files (handled by calendar, not Drive)
- Email signatures with embedded images
- Tiny images (<50KB) likely logos or tracking pixels
- Generic attachments from bulk/newsletter senders

## File Type Awareness

**Always store**: `.pdf`, `.docx`, `.xlsx`, `.csv`, `.pptx`, `.doc`, `.xls`
**Store if HIGH/MEDIUM**: `.png`, `.jpg`, `.jpeg`, `.tiff`, `.heic` (scanned documents)
**Skip**: `.ics`, `.vcf`, `.eml`, inline images, signature images

## Drive Path Conventions

Suggested storage paths follow this hierarchy:

```
{Year}/
├── Finance/
│   ├── Invoices/{Vendor}/{filename}
│   ├── Tax/{Authority or Advisor}/{filename}
│   ├── Statements/{Bank}/{filename}
│   └── Insurance/{Provider}/{filename}
├── Contracts/{Company}/{filename}
├── Legal/{Category}/{filename}
├── HR/{Company or Category}/{filename}
└── Projects/{Project Name}/{filename}
```

### Path derivation rules

1. **Year** — use the email date's year (not today's year if email is older)
2. **Category** — derive from attachment content and email context using `email-categorization` patterns
3. **Subfolder** — use sender company/organization name, cleaned up:
   - `billing@stripe.com` → `Stripe`
   - `rechnungen@hetzner.de` → `Hetzner`
   - `hr@acme-corp.com` → `Acme Corp`
4. **Filename** — keep original filename unless generic:
   - `document.pdf` → rename to `{category}-{date}-{sender}.pdf` (e.g., `invoice-2026-02-stripe.pdf`)
   - `scan001.pdf` → rename to `{context}-{date}.pdf`
   - Already descriptive filenames → keep as-is

### Deduplication

- Before suggesting upload, note if a file with the same name already exists at the target path
- If duplicate detected, append `-{n}` or skip with a note in the briefing

## Reporting in Briefing

For each attachment suggested for Drive:

```
- [x] **{filename}** from {sender}
  - 📁 Suggested path: `{Drive path}`
  - **Importance**: {HIGH/MEDIUM}
  - **Reason**: {one-line, e.g., "Invoice from Stripe, Feb 2026"}
  - Source: 📧 [View email](https://mail.google.com/mail/u/0/#inbox/{message_id})
```
