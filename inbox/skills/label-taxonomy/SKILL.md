---
name: label-taxonomy
description: Defines recommended Gmail label hierarchy and naming conventions. Use when creating labels, reorganizing label structure, or proposing label changes. Triggers on label creation, label cleanup, or label organization tasks.
---

## Label Naming Conventions

- Use **English names** for label consistency across workspaces
- Use Gmail's nested label separator: `/` (e.g., `Finance/Invoices`)
- Detection patterns are **bilingual DE + EN** (see email-categorization skill)
- Only create labels that have matching emails — never create empty labels

## Recommended Label Hierarchy

Create only what's relevant per workspace:

```
Finance/
├── Invoices          # EN: invoice, receipt | DE: Rechnung, Quittung
├── Tax               # EN: tax, 1099, W-2 | DE: Steuer, Steuerbescheid, Finanzamt, Umsatzsteuer
├── Statements        # EN: statement, balance | DE: Kontoauszug, Saldo
└── Insurance         # EN: insurance, policy | DE: Versicherung, Police, Beitrag

Transactional/
├── Orders & Shipping # EN: order, shipping, tracking | DE: Bestellung, Versand, Sendungsverfolgung
└── Payments          # EN: payment, charge | DE: Zahlung, Abbuchung, Lastschrift

SaaS/
└── Notifications     # Automated service notifications

Clients/
└── [auto-detected]   # Created from frequently occurring business email domains

Newsletters/
└── [auto-detected]   # Created from high-volume newsletter senders
```

## Label Creation Rules

1. **Check existing labels first** — call `list_gmail_labels` before creating anything
2. **Reuse existing labels** when they match intent (even if naming differs slightly)
3. **Don't create labels with 0 matching emails** in the current analysis
4. **Workspace-appropriate labels**: business labels (Clients/) for business accounts, personal labels for personal accounts
5. **Propose renaming** poorly named existing labels in the briefing (Section C)

## Label Cleanup Rules

When reviewing existing labels:

1. **Empty labels** (0 messages) — propose deletion
2. **Duplicate labels** (similar names, same purpose) — propose merge
3. **Flat labels that should be nested** (e.g., `invoices` → `Finance/Invoices`) — propose restructure
4. **Overly specific labels** with very few messages — propose merge into parent
5. **System labels** (INBOX, SENT, DRAFT, etc.) — never touch these

## Applying Labels to Existing Emails

When labeling existing emails (before historic archive):

1. Search for emails matching each category's patterns
2. Use `batch_modify_gmail_message_labels` to apply labels in bulk
3. Process financial/tax emails FIRST (they must be labeled before the historic archive step)
4. Report count of emails labeled per category
