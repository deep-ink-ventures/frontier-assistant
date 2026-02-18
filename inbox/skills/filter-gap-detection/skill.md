---
name: filter-gap-detection
description: Detects emails that should have been caught by filters but weren't, and proposes new filters to close the gaps. Use when analyzing inbox for missed auto-archive opportunities. Triggers on daily briefing, filter review, or filter gap analysis tasks.
---

## Filter Gap Detection

Compare each unarchived inbox email against existing Gmail filters. An email is a "filter gap" if it matches a known low-value pattern but no existing filter caught it.

### Detection process

1. **Load existing filters** — get all filters via `list_gmail_filters`, extract their criteria (from, to, subject, hasAttachment, query)
2. **For each inbox email**, check:
   - Does it match any existing filter's criteria? If yes → not a gap
   - Does it match a category from `email-categorization` skill (newsletter, transactional, marketing)? If yes and no filter exists → **gap found**
3. **Group gaps** by sender pattern or category — don't propose one filter per email, propose one filter per pattern

### Gap categories (from `email-categorization` skill)

**Newsletter gap**: Email has `List-Unsubscribe` header or matches newsletter sender/subject patterns, but no filter skips inbox for this sender.

**Transactional gap**: Email is from `noreply@`, `notifications@`, or matches transactional patterns, but no filter exists.

**Marketing gap**: Email matches promotional/sales patterns, but no filter exists.

**SaaS notification gap**: Automated emails from tools (GitHub, Slack, Linear, Jira, etc.) that should be labeled and archived.

### Filter proposal rules

1. **Minimum threshold**: Only propose a filter if the pattern matches **3+ emails** in the current inbox (avoids over-filtering)
2. **Sender-based preferred**: Prefer `from:` criteria over `subject:` criteria (more reliable)
3. **Include action**: Every proposed filter must specify its action (skip inbox, mark read, apply label) — use `email-categorization` skill for action mapping
4. **Safety check**: Apply `safety-rules` skill — never propose filters matching security/OTP patterns
5. **No duplicates**: Don't propose a filter that overlaps with an existing one (even partial overlap → skip or note)
6. **Consolidate**: If multiple senders belong to the same service (e.g., `noreply@github.com` and `notifications@github.com`), propose a single filter with `from:*@github.com`

### Existing filter review

While analyzing gaps, also flag:

- **Stale filters**: Existing filters that match 0 emails in the current inbox (may be outdated)
- **Leaky filters**: Existing filters that should catch emails but some slip through (criteria too narrow)
- **Missing labels**: Filters that skip inbox but don't apply a label (makes emails hard to find)

### Reporting in Briefing

```
### New filters to create

- [x] **Filter**: From: `notifications@linear.app`
  - **Action**: Skip Inbox, Mark Read, Apply Label: `SaaS/Notifications`
  - **Gap**: {n} emails in inbox that would have been caught
  - **Sample subjects**: "Issue assigned to you", "Comment on PRJ-123"

### Existing filter issues

- [ ] **Stale**: Filter #{id} `from:oldservice@gone.com` — 0 matches, consider removing
- [ ] **Leaky**: Filter #{id} `from:noreply@github.com` — misses `notifications@github.com`
```
