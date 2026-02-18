# Inbox Plugin

Claude plugin for managing multiple Google Workspace inboxes. Categorizes emails (DE+EN), proposes labels and filters via an editable briefing, then executes approved actions.

## Prerequisites

- Claude Code with plugin support
- One or more [GWS MCP connectors](https://workspacemcp.com) running and configured in Claude's MCP settings

## Install

Upload the zip to Claude, or point Claude at this directory.

```sh
# from repo root
./build.sh inbox    # creates dist/inbox/v1.0.2/inbox.zip
```

## Commands

### `/inbox:initialize`

Run once (or rarely) to set up a workspace from scratch. Analyzes the last 3 months of inbox emails, then produces a briefing with:

- **Forward-looking filters** — auto-archive newsletters, marketing, transactional noise going forward
- **Label hierarchy** — creates structured labels (Finance/Invoices, Finance/Tax, Newsletters/, etc.) and applies them to matching emails
- **Filter/label cleanup** — removes unused filters, consolidates duplicates, nests flat labels
- **Archive** — archives and marks read ALL emails older than 1 month. No exceptions. No safety exclusions.

```
/inbox:initialize              # pick workspaces interactively
/inbox:initialize --all        # all connected workspaces
/inbox:initialize gws-acme     # specific workspace
```

After initialize, only the last month of emails remains in the inbox.

### `/inbox:briefing`

Run daily. Fetches full email content from the inbox and produces a briefing with:

- **Situation report** — high-traction threads where you're CC'd (scored HOT / ACTIVE)
- **Follow-ups** — sent emails from the last 2 weeks that haven't gotten a reply, with reminder drafts ready to send
- **Action items** — tasks assigned to you via forwards, direct requests, or thread mentions (EN+DE detection)
- **Draft replies** — contextual reply drafts for emails that need a response, matching language and tone
- **Attachment triage** — important attachments flagged for Google Drive storage
- **Filter & label gaps** — proposals for new filters and label corrections
- **Archive** — archives and marks read every email in the inbox. After execution, inbox is at zero.

```
/inbox:briefing                # pick workspaces interactively
/inbox:briefing --all          # all connected workspaces
/inbox:briefing gws-acme       # specific workspace
```

## How it works

1. **Discover** — detects connected `gws-*` MCP servers at runtime, asks which to process
2. **Analyze** — scans inbox (and sent mail), categorizes senders, extracts tasks, identifies follow-ups
3. **Brief** — writes a structured markdown briefing to `~/tmp/briefings/`; you review and edit checkboxes
4. **Execute** — applies only the actions you approved (send drafts, create filters, archive)

The briefing is a markdown file with checkboxes. You edit it in your editor — check what you approve, uncheck what you skip — then tell Claude to execute.

### Key rules

- **Initialize**: archives and marks read ALL emails >1 month. No exceptions, no safety exclusions.
- **Briefing**: empties the inbox completely. Zero emails remain.
- **Safety rules** apply only to forward-looking filter creation, never to archiving.
- **No deletion** — archive only. Labels keep things findable.

## Structure

```
.claude-plugin/plugin.json   Plugin manifest
commands/                     Slash commands
skills/                       Auto-activated domain knowledge
~/tmp/briefings/              Generated briefings (outside plugin dir)
```

## MCP servers

This plugin is opinionated about google workspaces. It assumes https://workspacemcp.com connectors gws-* are configured in Claude's MCP settings. * in this case is a google workspace and your workspace mcp runs locally, each one with a dedicated port.