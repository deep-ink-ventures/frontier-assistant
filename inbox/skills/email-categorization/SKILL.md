---
name: email-categorization
description: Categorizes emails using bilingual DE+EN heuristic patterns for labeling and filter proposals. Use when analyzing inbox emails, proposing filters, or categorizing senders. Triggers on email analysis, sender categorization, or inbox review.
---

## Email Categorization Rules

All patterns work in **both German (DE) and English (EN)**. Categorization is used for:
- Labeling emails correctly (especially before historic archive)
- Proposing forward-looking filters with appropriate actions
- Identifying archive candidates by engagement

**Important**: For historic cleanup (>3 months), ALL emails get archived regardless of category. Categorization ensures proper **labeling** before archiving.

## Categories (first match wins)

### 1. FINANCIAL

**Purpose**: Label with `Finance/*` hierarchy. Archive normally (label ensures findability).

**EN patterns**:
- Subject contains: invoice, receipt, tax, 1099, W-2, W-9, statement, payment, billing, refund, charge, subscription renewal
- From patterns: `billing@`, `invoices@`, `accounting@`, `finance@`, `*.bank.com`, `*paypal*`, `*stripe*`, `*wise.com`

**DE patterns**:
- Subject contains: Rechnung, Quittung, Steuer, Steuernummer, Umsatzsteuer, Steuerbescheid, Steuerberater, Finanzamt, Kontoauszug, Zahlung, Abbuchung, Lastschrift, Überweisung, Gutschrift, Mahnung, Beitrag, Einzug, SEPA, Steuererklärung, Lohnabrechnung
- From patterns: `buchhaltung@`, `rechnungen@`, `*.sparkasse.de`, `*.volksbank.de`, `*.commerzbank.de`, `*.deutsche-bank.de`, `*.postbank.de`, `*.ing.de`, `*.dkb.de`, `*.comdirect.de`, `*datev*`, `*lexoffice*`, `*sevdesk*`

**Sub-categories for labeling**:
- `Finance/Invoices` — Rechnung, invoice, receipt, Quittung
- `Finance/Tax` — Steuer*, tax, 1099, W-2, Finanzamt, Steuerbescheid
- `Finance/Statements` — Kontoauszug, statement, balance, Saldo
- `Finance/Insurance` — Versicherung, insurance, policy, Police, Beitrag

### 2. TRANSACTIONAL

**Purpose**: Low-value automated messages. Strong archive candidates.

**EN patterns**:
- From: `noreply@`, `no-reply@`, `notifications@`, `automated@`, `mailer-daemon@`
- Subject: shipping confirmation, order update, delivery, tracking, your order, password changed
- Signal: single-message threads, no replies from user

**DE patterns**:
- Subject: Versandbestätigung, Bestellbestätigung, Lieferung, Sendungsverfolgung, Paket, Zustellung, Ihre Bestellung, Auftragsbestätigung, Passwort geändert
- Signal: single-message threads, no replies from user

**Filter action**: Skip Inbox, Mark Read, Apply Label: `Transactional/`

### 3. NEWSLETTER

**Purpose**: Recurring content emails. Archive if low engagement.

**Patterns (language-independent)**:
- Has `List-Unsubscribe` header
- From: `newsletter@`, `digest@`, `updates@`, `news@`, `weekly@`

**EN patterns**:
- Subject: weekly, digest, roundup, newsletter, monthly update, what's new

**DE patterns**:
- Subject: Wochenübersicht, Zusammenfassung, Newsletter, Rundschau, Neuigkeiten, Wochenrückblick, Monatsübersicht

**Key signal**: 0% open rate over analysis period = strong archive candidate

**Filter action**: Skip Inbox, Mark Read, Apply Label: `Newsletters/`

### 4. MARKETING / SALES

**Purpose**: Promotional and unsolicited sales emails. Strong archive candidates.

**EN patterns**:
- Subject: offer, sale, discount, limited time, deal, exclusive, special offer, act now, don't miss
- From: `marketing@`, `sales@`, `promo@`, `offers@`, `deals@`

**DE patterns**:
- Subject: Angebot, Rabatt, Aktion, Sonderangebot, Nur für kurze Zeit, Gutschein, Exklusiv, Jetzt zugreifen, Nicht verpassen, Gratis
- From: `marketing@`, `vertrieb@`, `angebote@`, `aktionen@`

**Filter action**: Skip Inbox, Archive, Mark Read

### 5. PERSONAL / IMPORTANT

**Purpose**: Emails to keep in inbox (for <=3 months).

**Signals**:
- From individual addresses (not `noreply`, not automated)
- Multi-message threads with back-and-forth replies
- Starred or marked important by user
- Recent calendar invitations

**No filter action** — these stay in inbox.

## Engagement Calculation

For each sender (used for <=3 month emails only):
1. Count total emails from sender in analysis period
2. Count emails that were read (no UNREAD label)
3. `engagement_rate = read_count / total_count`

**Moderate threshold** (<=3 months): Archive candidate if `engagement_rate < 10%` AND `total_count > 3`

**Note**: Emails >3 months are ALWAYS archived during historic cleanup. Engagement is irrelevant for them.

## Filter Proposal Format

Every proposed filter MUST include its action. Example:

```
Filter: From: newsletter@example.com
  Criteria: from:newsletter@example.com
  Action: Skip Inbox, Mark Read, Apply Label: Newsletters/
  Matches: 47 emails in analysis period
  Sample: "Weekly digest - Jan 2026", "Your February roundup"
```
