# /inbox:briefing

Daily inbox triage: review all inbox emails, draft replies, suggest filter gaps and Drive storage, then archive everything. After execution, inbox is empty. Assumes `/inbox:initialize` has been run.

## Usage

```
/inbox:briefing
/inbox:briefing --all
/inbox:briefing gws-acme
/inbox:briefing gws-acme gws-personal
```

## What This Command Does

1. **Scans all unarchived emails** across selected workspaces
2. **Surfaces high-traction threads** — CC'd threads with lots of activity you should know about (`task-extraction` skill)
3. **Extracts action items** — tasks assigned to you via forwards, direct requests, or thread mentions (`task-extraction` skill)
4. **Reviews sent mail** — flags outbound emails from the last 2 weeks that haven't received a reply, creates follow-up reminder drafts
5. **Drafts replies** for emails that need answers — creates Gmail drafts, does NOT send (`draft-replies` skill)
6. **Flags important attachments** — suggests storing in Google Drive (`attachment-triage` skill)
7. **Detects filter gaps** — emails that should have been auto-archived but weren't (`filter-gap-detection` skill)
8. **Checks label accuracy** — suggests missing or corrected labels (`email-categorization` + `label-taxonomy` skills)
9. **Produces an executive summary** using the daily briefing variant of the `briefing-pattern` skill
10. **Archives everything and empties the inbox** — no exceptions

Everything is presented in an editable briefing BEFORE any action is taken (except draft creation, which is non-destructive).

## File Output Rules

- **Final briefing**: `~/tmp/briefings/{connector}-briefing-{YYYY-MM-DD}.md` — this stays.
- **Intermediate artifacts** (JSON chunks, ID lists, analysis data): write to `~/tmp/artifacts/` if needed.
- **Clean up**: delete everything in `~/tmp/artifacts/` when the command finishes (after Phase 5 summary). No leftover files.

## Important Distinctions from `/inbox:initialize`

| | Initialize | Briefing |
|---|---|---|
| **When to run** | Once (or rarely) | Daily |
| **Inbox state** | May have months of backlog | Small (post-initialize) |
| **Email fetch format** | `metadata` (sender, subject, labels) | `full` (includes body for draft generation) |
| **Drafts replies** | No | Yes — creates drafts for emails needing response |
| **Drive storage** | No | Yes — suggests storing important attachments |
| **End state** | Only last month remains (everything older archived) | **Inbox completely empty** |
| **Filter proposals** | From-scratch analysis | Gap detection against existing filters |

## Step-by-Step Workflow

### Phase 1: Workspace Selection

Follow the `workspace-selection` skill:

1. Discover connected `gws-*` MCP connectors from available tool prefixes
2. If user specified workspaces in the command, use those
3. If user said `--all`, use all discovered connectors
4. Otherwise, use `AskUserQuestion` to let user pick (multi-select)

Process selected workspaces **sequentially** — complete all phases for one before starting the next.

### Phase 2: Analysis (per workspace)

For each selected workspace (connector name: `{connector}`):

#### 2a. Fetch existing configuration

```
Call: mcp__{connector}__list_gmail_labels
→ Get all labels with IDs. Map label names to IDs for later use.

Call: mcp__{connector}__list_gmail_filters
→ Get all existing filters. Note criteria and actions for gap detection.
```

#### 2b. Fetch all unarchived inbox emails

```
Call: mcp__{connector}__search_gmail_messages
  query: "in:inbox"
  max_results: 500 (paginate if needed)
→ Get all message IDs currently in inbox
```

Then batch-retrieve **full content** (needed for draft generation and attachment analysis):

```
Call: mcp__{connector}__get_gmail_messages_content_batch
  message_ids: [batch of ~25 at a time — full format is heavier]
  format: "full"
→ Get sender, subject, date, labels, read status, body, attachments for each message
```

#### 2c. Categorize and analyze

Using the `email-categorization` skill (bilingual DE+EN patterns):

1. Categorize each email by sender/subject patterns
2. Identify financial/tax emails for labeling (using `label-taxonomy` skill)
3. Apply `safety-rules` skill to forward-looking filter proposals only (never to archiving)

#### 2d. Review sent mail for unanswered outbound

Scan sent emails from the last 2 weeks for threads where the user is waiting on a reply.

```
Call: mcp__{connector}__search_gmail_messages
  query: "in:sent after:{2-weeks-ago-YYYY/MM/DD}"
  max_results: 200
→ Get sent message IDs
```

Batch-retrieve metadata:

```
Call: mcp__{connector}__get_gmail_messages_content_batch
  message_ids: [batch of ~50 at a time]
  format: "metadata"
→ Get thread_id, to, subject, date for each sent message
```

For each sent message, check if the thread has a newer inbound reply:

1. Group sent messages by thread_id
2. For each thread, check if there is a reply from the recipient **after** the user's last sent message
3. If no reply exists and the sent message contained a question, request, or expected a response — flag it
4. Skip automated/transactional outbound (noreply addresses, auto-forwards, calendar RSVPs)
5. For each flagged thread, create a follow-up reminder draft:

```
Call: mcp__{connector}__create_gmail_draft
  to: [original recipient]
  subject: "Re: {original subject}"
  body: "{short follow-up reminder}"
  thread_id: "{thread_id}"
→ Creates reminder draft — does NOT send
```

Follow-up drafts use the `draft-replies` skill for language/tone matching. Keep reminders brief and polite (1–2 sentences).

#### 2e. Extract action items and high-traction threads

Using the `task-extraction` skill:

1. Scan every email for task assignment language (EN+DE), forwarded tasks, implicit tasks from unanswered threads
2. Classify action items as HIGH or MEDIUM confidence
3. Identify CC'd threads with high traction (3+ messages, 2+ participants, recent activity)
4. Score threads as HOT or ACTIVE
5. If an action item also needs a reply, flag it for both Section C (task) and Section D (draft reply)

#### 2f. Detect filter gaps and stale filters

Using the `filter-gap-detection` skill:

1. Compare each inbox email against existing filters from step 2a
2. Emails matching low-value patterns (newsletter, transactional, marketing) with no catching filter → gap
3. Group gaps by sender pattern — propose one filter per pattern (minimum 3 emails to trigger)
4. Flag stale/leaky existing filters (criteria no longer match any recent emails)
5. Identify redundant filters (multiple filters targeting the same sender/pattern)
6. Identify conflicting filters (contradictory actions on the same criteria)
7. Propose removal of unused filters (no matches in last 3 months)
8. Apply `safety-rules` skill: never propose filters matching security/OTP patterns

#### 2g. Check label accuracy and prune stale labels

Using the `email-categorization` and `label-taxonomy` skills:

1. For each email, check if it should have a label it doesn't have
2. Propose new labels only if they'd apply to 2+ emails
3. Suggest corrections (wrong category, missing sub-label)
4. Identify empty labels (0 messages) — propose removal
5. Identify duplicate/near-duplicate labels — propose merge
6. Identify flat labels that should be nested (e.g., `invoices` → `Finance/Invoices`)

#### 2h. Triage attachments

Using the `attachment-triage` skill:

1. Identify emails with attachments (PDFs, documents, spreadsheets)
2. Score each attachment: HIGH / MEDIUM / LOW importance
3. For HIGH and MEDIUM: suggest a Google Drive path following the skill's conventions
4. Skip LOW importance attachments (marketing, logos, tracking pixels)

#### 2i. Identify emails needing replies and create drafts

Using the `draft-replies` skill:

1. Detect emails needing a response (high/medium confidence only)
2. For each, generate a contextual draft reply matching language and tone
3. Create the draft in Gmail:

```
Call: mcp__{connector}__create_gmail_draft
  to: [original sender]
  subject: "Re: {original subject}"
  body: "{drafted reply}"
  thread_id: "{thread_id}"
→ Creates draft — does NOT send
```

4. Track all created draft IDs for the briefing

#### 2j. Archive plan

**Every email in the inbox will be archived and marked read.** No exceptions. No safety exclusions.

The briefing groups emails by category for visibility, but archiving is unconditional. After execution, the inbox is empty.

### Phase 3: Briefing

Follow the **Daily Briefing Variant** of the `briefing-pattern` skill:

1. Generate the briefing markdown file with all sections (A through G)
2. Write to `~/tmp/briefings/{connector}-briefing-{YYYY-MM-DD}.md`
3. Tell the user: **"Daily briefing written to `{path}`. Review all sections. Drafts for replies and follow-ups are already in Gmail — send them yourself if they look good. Edit checkboxes for the remaining actions, then tell me to execute."**
4. **Stop and wait** for user confirmation

### Phase 4: Execution

When the user says to execute, follow the `briefing-pattern` skill's sign-off flow:

1. Read the briefing file back from disk
2. Parse checkboxes: `[x]` = approved, `[ ]` = skipped
3. Execute in this order (matches `briefing-pattern` daily execution order):

#### 4a. Save attachments to Drive (from Section E)

For each approved attachment:
```
Call: mcp__{connector}__get_gmail_message_attachment
  message_id: "{message_id}"
  attachment_id: "{attachment_id}"
→ Get attachment data

Call: mcp__{connector}__upload_drive_file
  name: "{filename}"
  parent_path: "{suggested Drive path}"
  content: "{attachment data}"
→ Upload to Google Drive
```

#### 4b. Create new labels (from Section F)

For each approved new label:
```
Call: mcp__{connector}__manage_gmail_label
  action: "create"
  label_name: "{label}"
```

#### 4c. Apply label corrections (from Section F)

For each approved label application:
```
Call: mcp__{connector}__batch_modify_gmail_message_labels
  message_ids: [matching IDs]
  add_label_ids: ["{label_id}"]
```

#### 4d. Create Gmail filters (from Section F)

For each approved filter:
```
Call: mcp__{connector}__create_gmail_filter
  criteria: { from: "...", subject: "...", ... }
  action: { removeLabelIds: ["INBOX"], addLabelIds: ["..."], markAsRead: true }
```

Note: "Skip Inbox" = `removeLabelIds: ["INBOX"]`. "Mark Read" = `markAsRead: true`.

#### 4e. Archive and mark read ALL remaining inbox emails (from Section G)

This is unconditional. Every email still in the inbox gets archived and marked read.

```
Call: mcp__{connector}__search_gmail_messages
  query: "in:inbox"
→ Get ALL remaining message IDs

Call: mcp__{connector}__batch_modify_gmail_message_labels
  message_ids: [batch of ~100 IDs at a time]
  remove_label_ids: ["INBOX", "UNREAD"]
→ Repeat for all batches
```

**No exceptions. No safety exclusions. Inbox must be empty after this step.**

### Phase 5: Summary Report

After execution completes, report:

```
## Daily Briefing Executed: {connector}

### Action Items Surfaced
- {n} tasks extracted ({n} high confidence, {n} medium)
- {n} high-traction threads flagged

### Drafts Created
- Follow-up reminders: {n} drafts in Gmail
- Reply drafts: {n} drafts in Gmail
- **Send them yourself** from Gmail when ready

### Files Saved to Drive
- Uploaded: {n} attachments
- Paths: {list of Drive paths}

### Filters & Labels
- Created: {n} new filters
- Labels created/corrected: {n}

### Archived
- {n} emails archived and marked read
- Inbox: **0 emails remaining**

Your inbox is empty. Run `/inbox:briefing` again tomorrow.
```

## Error Handling

- **Rate limit (429)**: Wait 30 seconds, show progress so far, retry
- **Auth expired**: Tell user which workspace needs re-authentication. Skip that workspace, continue others.
- **Draft creation fails**: Log error, include email in summary as "draft failed — compose manually"
- **Drive upload fails**: Log error, include in summary as "upload failed — save manually"
- **Empty inbox**: "Inbox is already empty! Nothing to triage." — not an error
- **Large inbox (>500 emails)**: Warn that initialize may need re-running, proceed with progress updates
- **Batch size**: Use batches of ~100 message IDs for `batch_modify_gmail_message_labels`. If errors, reduce to 50.

## Rate Limit Awareness

- `get_gmail_messages_content_batch` with `format: "full"`: heavier than metadata — use batches of ~25
- `create_gmail_draft`: 100 quota units per call
- `create_gmail_filter`: 100 quota units per call
- Gmail API limit: 15,000 quota units per user per minute
- If creating 10+ drafts, add brief pauses between calls
- Prefer batch operations over single-message modifications
