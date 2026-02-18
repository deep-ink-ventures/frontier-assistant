# Frontier Assistant

Opinionated workspace orchestrator for Google Workspace — designed for the busy executive who moves fast and breaks things.

## How It Works

Each Google Workspace account connects through a dedicated [workspacemcp.com](https://workspacemcp.com) proxy running locally on its own port. Claude sees these as `gws-*` MCP connectors and orchestrates across all of them.

## Plugins

All commands create a Briefing Document with suggested steps, you review, claude executes.

| Plugin | Command | What it does |
|--------|---------|-------------|
| **inbox** | `/inbox:initialize` | Set up labels, filters, archive everything >1 month — no exceptions |
| | `/inbox:briefing` | Daily briefind and exec summary, action plan, triage: draft replies, suggest filters & Drive storage, then empty the inbox completely. |

Growing list of tasks for smooth, AI-first tooling.

## Build

```sh
./build.sh <plugin-name>
# e.g. ./build.sh inbox → dist/inbox/v1.0.2/inbox.zip
```
