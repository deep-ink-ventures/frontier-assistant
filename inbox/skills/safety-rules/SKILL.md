---
name: safety-rules
description: Defines safety rules for forward-looking Gmail filter creation only. Triggers on filter creation or filter review. NEVER applies to archiving — archiving has zero exceptions.
---

## Scope

**These safety rules apply ONLY to forward-looking Gmail filter creation** (ongoing automation for future incoming emails).

They do **NOT** apply to archiving. Ever. Not to historic cleanup, not to daily briefing triage, not to any archive action. All emails get archived when the command says so. Archive is not deletion.

## Forward-Looking Filter Safety Rules

Never create ongoing filters that auto-archive these patterns:

### 1. Security & Authentication

**EN patterns**:
- From: `*@accounts.google.com`, `security@*`, `*@accountprotection.*`, `*@login.*`
- Subject matches: OTP, verification code, password reset, security alert, suspicious activity, new device, 2FA, two-factor, sign-in attempt, account recovery

**DE patterns**:
- Subject matches: Bestätigungscode, Verifizierungscode, Sicherheitswarnung, Passwort zurücksetzen, Neues Gerät, Zwei-Faktor, Anmeldeversuch, Verdächtige Aktivität, Kontowiederherstellung

**Body signals**: Contains 4-8 digit codes that look like OTP

### 2. User-Flagged Content

- Starred messages — never auto-archive
- Messages marked Important — never auto-archive

### 3. Time-Sensitive Content

**EN patterns**:
- Subject contains: urgent, deadline, asap, action required, expires today, final notice
- Calendar invitations (`.ics` attachments)

**DE patterns**:
- Subject contains: dringend, Frist, sofort, Handlungsbedarf, läuft ab, letzte Mahnung

### 4. Active Conversations

- Threads with replies in the last 7 days — don't auto-archive the thread

## What is NOT protected

**Financial/tax emails are NOT excluded from archiving.** They are:
1. **Labeled** first (`Finance/Tax`, `Finance/Invoices`, etc.)
2. Then archived normally

Labels make them findable. Archive keeps inbox clean. This is intentional.

## When to apply these rules

- When proposing new Gmail filters (initialize Section A, briefing filter gaps)
- When reviewing existing filters for safety issues (initialize Section C)

## When NOT to apply these rules

- **Any archiving action** — archive ALL emails, no exceptions, no safety exclusions
- Label application — labels are informational, not destructive
- Daily briefing triage — everything gets archived and marked read

## Reporting

When safety rules exclude patterns from filter proposals, report:

```
Protected from auto-archive in ongoing filters:
  - {n} security/authentication patterns
  - {n} starred/important patterns
  - {n} time-sensitive patterns
  - {n} active conversation patterns
```
