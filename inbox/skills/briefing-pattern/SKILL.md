---
name: briefing-pattern
description: Generates editable markdown briefings with proposed actions and handles sign-off workflow. Use when any command needs user approval before executing bulk or destructive operations. Triggers on briefing generation, action sign-off, or execute-after-review flows.
---

## Briefing-First Execution Pattern

Every command that modifies data follows this pattern:

1. **Analyze** — Read data, compute suggestions
2. **Brief** — Write structured markdown briefing to file
3. **Confirm** — User edits in their preferred editor, then tells Claude to execute
4. **Execute** — Read file back, apply only checked/approved actions
5. **Report** — Show what was done

## Briefing File Format

Write briefings to: `~/tmp/briefings/{connector-name}-{YYYY-MM-DD}.md`

### Structure

```markdown
# Briefing: {connector-name}
**Date**: {date}
**Emails analyzed**: {count}
**Date range**: {oldest} to {newest}

---

## Section A — Forward-Looking Filters

Proposed Gmail filters for ongoing automation. Safety rules applied (OTP, security alerts protected).

- [x] **Filter**: From: `newsletter@example.com`
  - **Action**: Skip Inbox, Mark Read, Apply Label: `Newsletters/`
  - **Matches**: 47 emails in analysis period
  - **Sample subjects**: "Weekly digest", "Monthly roundup"

- [x] **Filter**: From: `noreply@shipping.com`
  - **Action**: Skip Inbox, Mark Read, Apply Label: `Transactional/Orders & Shipping`
  - **Matches**: 12 emails
  - **Sample subjects**: "Your order has shipped", "Delivery confirmation"

## Section B — Label Organization

### New labels to create

- [x] `Finance/Invoices`
- [x] `Finance/Tax`
- [x] `Newsletters/`

### Emails to label

- [x] **Finance/Invoices** — 23 emails (from: billing@stripe.com, rechnungen@example.de, ...)
- [x] **Finance/Tax** — 8 emails (subjects matching: Steuerbescheid, tax return, ...)

## Section C — Existing Filter/Label Cleanup

### Filters to remove

- [x] Filter #abc123: `from:oldservice@gone.com` — 0 matches in 3 months, service discontinued
- [ ] Filter #def456: `subject:weekly` — overlaps with proposed new filter

### Labels to remove

- [x] `Old-Project/` — 0 emails, unused
- [ ] `Misc` — 3 emails, consider merging into another label

## Section D — Historic Cleanup (>3 months)

**{count} emails older than 3 months will be archived.**

All financial/tax emails have been labeled in Section B BEFORE this step.
Archive = remove from inbox. Nothing is deleted. Everything remains searchable.

- [x] Archive all {count} emails older than 3 months

## Section E — Recent Email Triage (<=3 months)

Archive candidates based on low engagement (moderate threshold).
Safety exclusions applied: OTP, security, starred, important emails excluded.

- [x] **noreply@service.com** — 15 emails, 0% opened → Archive + Mark Read
- [x] **marketing@vendor.com** — 8 emails, 5% opened → Archive + Mark Read
- [ ] **updates@tool.io** — 4 emails, 8% opened → Archive + Mark Read

### Safety Exclusions (not included above)

- {n} security/authentication emails protected
- {n} starred/important emails protected
- {n} active conversations protected

---
*Edit this file: uncheck items you want to skip, add notes. Then tell Claude to execute.*
```

## Daily Briefing Variant

Used by `/inbox:briefing`. Same Analyze → Brief → Confirm → Execute → Report pattern, different sections.

Write to: `~/tmp/briefings/{connector-name}-briefing-{YYYY-MM-DD}.md`

### Structure

```markdown
# Daily Briefing: {connector-name}
**Date**: {date}
**Emails in inbox**: {count}

---

## Section A — Inbox Summary

One executive paragraph summarizing what's in the inbox. Key themes, notable
senders, volume patterns, overall tone.

> Your Acme inbox has 34 unarchived emails. Most activity is from the engineering
> team (12 threads about the Q1 release), 6 client emails awaiting response, and
> the usual flow of SaaS notifications. Three invoices arrived this week.

## Section B — Important Items & Deadlines

Emails requiring attention, sorted by urgency. Each with a direct Gmail link.

- [x] **DEADLINE Feb 16** — Tax filing reminder from Finanzamt
  - 📧 [View email](https://mail.google.com/mail/u/0/#inbox/{message_id})
  - Action needed: File by Feb 16 or request extension

- [x] **ACTION** — Contract review from Acme Corp (received Feb 13)
  - 📧 [View email](https://mail.google.com/mail/u/0/#inbox/{message_id})
  - Attachment: service-agreement-2026.pdf (flagged for Drive in Section D)

- [x] **FYI** — Team standup notes from Sarah (received Feb 14)
  - 📧 [View email](https://mail.google.com/mail/u/0/#inbox/{message_id})
  - No action needed, informational

## Section C — Draft Replies

{n} draft replies created. Review in [Drafts folder](https://mail.google.com/mail/u/0/#drafts).

Uses `draft-replies` skill format:

- [x] **Reply to**: {sender} — "{subject}"
  - **Why**: {reason, e.g., "Direct question, unanswered 2 days"}
  - **Draft preview**: "{first 100 chars}..."
  - **Confidence**: {High/Medium}
  - Draft ID: {draft_id}

### Drafts marked [x] will be SENT when you execute. Uncheck to keep as draft only.

## Section D — Attachments for Drive

Uses `attachment-triage` skill format:

- [x] **{filename}** from {sender}
  - 📁 Suggested path: `{Drive path}`
  - **Importance**: {HIGH/MEDIUM}
  - **Reason**: {one-line}
  - Source: 📧 [View email](https://mail.google.com/mail/u/0/#inbox/{message_id})

## Section E — Auto-Archive & Low Priority

{n} emails to archive and mark as read.

Summary: {one paragraph — e.g., "14 SaaS notifications from GitHub, Slack, and
Linear; 6 read newsletters; 3 shipping confirmations from last week."}

- [x] **Archive** — {sender pattern} ({n} emails): {sample subjects}
- [x] **Archive** — {sender pattern} ({n} emails): {sample subjects}

## Section F — New Rules & Filter Gaps

Uses `filter-gap-detection` skill format:

### New filters to create

- [x] **Filter**: From: `notifications@linear.app`
  - **Action**: Skip Inbox, Mark Read, Apply Label: `SaaS/Notifications`
  - **Gap**: {n} emails that would have been caught
  - **Sample subjects**: "Issue assigned to you", "Comment on PRJ-123"

### Label corrections

- [x] **Add label** `Finance/Invoices` to {n} emails from billing@stripe.com

### Existing filter issues

- [ ] **Stale**: Filter #{id} — 0 matches, consider removing

---
*Review this briefing. Edit checkboxes as needed. Then tell Claude to execute.*
*[x] = approved, [ ] = skipped*
```

### Daily Briefing Execution Order

1. Create new labels (Section F)
2. Apply label corrections (Section F)
3. Create new Gmail filters (Section F)
4. Send approved drafts (Section C)
5. Save approved attachments to Drive (Section D)
6. Archive low-priority emails (Section E)
7. Mark all processed emails as read

## Sign-Off Flow

After writing the briefing:

1. Tell the user: **"Briefing written to `{path}`. Open it in your editor, review the checkboxes, then tell me to execute."**
2. Wait for the user to say "execute", "go ahead", "run it", or similar
3. Read the file back from disk
4. Parse checkboxes: `[x]` = approved, `[ ]` = skipped
5. Execute ONLY the approved actions
6. Report results with counts

## Execution Order

When executing an approved briefing, follow this order:

1. Create new labels (Section B)
2. Apply labels to existing emails (Section B)
3. Create new Gmail filters (Section A)
4. Delete approved filters/labels (Section C)
5. Archive recent email candidates (Section E)
6. Archive all historic emails >3 months (Section D)
7. Mark all archived emails as read
