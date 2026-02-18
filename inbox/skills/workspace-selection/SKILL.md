---
name: workspace-selection
description: Discovers and selects Google Workspace MCP connectors dynamically. Use when any command needs to operate on one or more GWS workspaces. Triggers on workspace selection, multi-workspace operations, or when commands reference gws-* connectors.
---

## Workspace Discovery

Discover available GWS connectors at runtime. **Never hardcode workspace names or email addresses.**

### How to discover workspaces

1. Check which MCP tools are available with the `mcp__gws-` prefix
2. Extract unique connector names from the tool prefixes (e.g., `mcp__gws-acme__search_gmail_messages` → connector is `gws-acme`)
3. Each unique `gws-*` prefix represents one connected workspace
4. The actual email address for each workspace is NOT stored in the plugin — it comes from the connector itself

### Selection modes

**Mode 1 — All workspaces** (user says "all" or uses `--all`):
- Process every discovered `gws-*` connector
- Process them sequentially, one at a time

**Mode 2 — User selects** (default):
- List all discovered connectors by name
- Use `AskUserQuestion` to let the user pick one or more
- Allow multi-select

**Mode 3 — User specifies in command** (user names specific workspaces):
- Use only the workspaces the user mentioned
- Validate they exist as connected MCP servers

### Processing order

- Always process workspaces **sequentially** (ADR-2)
- Complete all phases for one workspace before moving to the next
- Show clear separation between workspace results in output

### Adding new workspaces

New workspaces are automatically discovered when:
1. A new `gws-*` MCP server is added to `.mcp.json`
2. The server is running and accessible
3. No plugin file changes needed — discovery is fully dynamic
