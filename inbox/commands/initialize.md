# /inbox:initialize

Set up Gmail with organized labels, smart filters, and clean up the historic inbox. Works across all connected Google Workspace accounts.

## Usage

```
/inbox:initialize
/inbox:initialize --all
/inbox:initialize gws-acme
/inbox:initialize gws-acme gws-personal
```

## What This Command Does

1. **Sets up forward-looking Gmail filters** with actions (skip inbox, archive, mark read, apply label)
2. **Organizes labels** into a clean nested hierarchy (Finance/Invoices, Finance/Tax, etc.)
3. **Reviews and cleans up** existing filters and labels (removes unused, consolidates duplicates)
4. **Archives and marks read ALL emails older than 1 month** — no exceptions, no safety exclusions

Everything is presented in an editable briefing BEFORE any action is taken.

## File Output Rules

- **Final briefing**: `~/tmp/briefings/{connector}-{YYYY-MM-DD}.md` — this stays.
- **Intermediate artifacts** (JSON chunks, ID lists, analysis data): write to `~/tmp/artifacts/` if needed.
- **Clean up**: delete everything in `~/tmp/artifacts/` when the command finishes (after Phase 5 summary). No leftover files.

## Archiving Rule

**After initialize completes, there must be ZERO emails older than 1 month in the inbox.**

No exceptions. No safety exclusions. OTP codes, security alerts, starred, important — everything >1 month gets archived and marked read. Archive is not deletion. Everything remains searchable.

Safety rules (OTP protection, starred/important exclusions) apply **only to forward-looking filter creation** — never to archiving.

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
→ Get all existing filters. Note criteria and actions.
```

#### 2b. Search inbox emails (last 3 months)

```
Call: mcp__{connector}__search_gmail_messages
  query: "in:inbox after:{3-months-ago-YYYY/MM/DD}"
  max_results: start with 500, paginate if needed
→ Get message IDs
```

Then batch-retrieve metadata:

```
Call: mcp__{connector}__get_gmail_messages_content_batch
  message_ids: [batch of IDs, ~50 at a time]
  format: "metadata"
→ Get sender, subject, date, labels, read status for each message
```

Only the last 3 months are analyzed for filter proposals, labeling patterns, and engagement rates. Anything older gets bulk archived without deep analysis — daily briefings will refine filters over time.

#### 2d. Categorize and analyze

Using the `email-categorization` skill (bilingual DE+EN patterns):

1. Categorize each email by sender/subject patterns
2. Calculate engagement rate per sender (read / total)
3. Identify financial/tax emails for labeling (using `label-taxonomy` skill for hierarchy)
4. Identify newsletter/marketing senders for filter proposals
5. Identify transactional senders for filter proposals
6. Apply `safety-rules` skill to forward-looking filter proposals only (never to archiving)

#### 2e. Review existing filters and labels

1. **Unused filters**: Filters where no analyzed emails match the criteria
2. **Redundant filters**: Multiple filters targeting the same sender/pattern
3. **Conflicting filters**: Filters with contradictory actions
4. **Empty labels**: Labels with 0 messages
5. **Duplicate labels**: Labels with similar names/purpose
6. **Flat labels**: Labels that should be nested (e.g., `invoices` → `Finance/Invoices`)

### Phase 3: Briefing

Follow the `briefing-pattern` skill:

1. Generate the briefing markdown file with all 4 sections (A through D)
2. Write to `~/tmp/briefings/{connector}-{YYYY-MM-DD}.md`
3. Tell the user: **"Briefing written to `{path}`. Open it in your editor, review and edit the checkboxes, then tell me to execute."**
4. **Stop and wait** for user confirmation

### Phase 4: Execution

When the user says to execute:

1. Read the briefing file back from disk
2. Parse checkboxes: `[x]` = approved, `[ ]` = skipped
3. Execute in this order:

#### 4a. Create new labels (from Section B)

For each approved label:
```
Call: mcp__{connector}__manage_gmail_label
  action: "create"
  label_name: "{label}"
```

#### 4b. Apply labels to existing emails (from Section B)

For each approved labeling group:
```
Call: mcp__{connector}__search_gmail_messages
  query: "{category search query}"

Call: mcp__{connector}__batch_modify_gmail_message_labels
  message_ids: [matching IDs]
  add_label_ids: ["{label_id}"]
```

**Process financial/tax emails FIRST** — they must be labeled before the historic archive step.

#### 4c. Create Gmail filters (from Section A)

For each approved filter:
```
Call: mcp__{connector}__create_gmail_filter
  criteria: { from: "...", subject: "...", ... }
  action: { removeLabelIds: ["INBOX"], addLabelIds: ["..."], markAsRead: true }
```

Note: "Skip Inbox" = `removeLabelIds: ["INBOX"]`. "Archive" = same thing. "Mark Read" = `markAsRead: true`.

#### 4d. Delete unused filters/labels (from Section C)

For each approved deletion:
```
# Delete filter
Call: mcp__{connector}__delete_gmail_filter
  filter_id: "{id}"

# Delete label
Call: mcp__{connector}__manage_gmail_label
  action: "delete"
  label_id: "{id}"
```

#### 4e. Archive ALL emails older than 1 month (from Section D)

```
Call: mcp__{connector}__search_gmail_messages
  query: "in:inbox before:{1-month-ago-YYYY/MM/DD}"
→ Get ALL message IDs (paginate through all results)

Call: mcp__{connector}__batch_modify_gmail_message_labels
  message_ids: [batch of ~100 IDs at a time]
  remove_label_ids: ["INBOX", "UNREAD"]
→ Repeat for all batches
```

**No exceptions. No safety exclusions. Everything >1 month gets archived and marked read.**

### Phase 5: Summary Report

After execution completes, report:

```
## Setup Complete: {connector}

### Labels
- Created: {n} new labels
- Cleaned: {n} labels removed

### Filters
- Created: {n} new forward-looking filters
- Removed: {n} unused/redundant filters

### Emails Archived
- Older than 1 month: {n} emails archived and marked read
- Total: {n} emails

### Labels Applied
- Finance/Invoices: {n} emails
- Finance/Tax: {n} emails
- [other labels]: {n} emails each

Your inbox now contains only emails from the last month.
No email older than 1 month remains.
Forward-looking filters will keep it clean going forward.
```

## Error Handling

- **Rate limit (429)**: Wait 30 seconds, show progress so far, retry
- **Auth expired**: Tell user which workspace needs re-authentication. Skip that workspace, continue others.
- **Network failure**: Show what completed vs. what's pending. User can re-run safely.
- **Empty inbox**: "Nothing to clean up!" — not an error
- **Large inbox (>10,000 emails)**: Warn about analysis time, proceed with progress updates
- **Batch size**: Use batches of ~100 message IDs for `batch_modify_gmail_message_labels`. If errors, reduce to 50.

## Rate Limit Awareness

- `batch_modify_gmail_message_labels`: 50 quota units per call
- `create_gmail_filter`: 100 quota units per call
- Gmail API limit: 15,000 quota units per user per minute
- If creating 20+ filters, add brief pauses between calls
- Prefer batch operations over single-message modifications
