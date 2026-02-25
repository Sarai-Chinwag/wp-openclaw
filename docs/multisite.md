# Multisite

WP-OpenClaw supports WordPress Multisite installations. Data Machine is designed for **per-site activation** — activate it on individual subsites that need agent capabilities, not network-wide.

## Setup

WP-OpenClaw sets up a standard WordPress installation. To convert to multisite after setup:

```bash
wp core multisite-convert --allow-root
```

Then create subsites as needed:

```bash
wp site create --slug=new-site --allow-root
```

## Activating Data Machine on Subsites

Data Machine should be activated per-site, not network-activated:

```bash
# Activate on a specific subsite
wp plugin activate data-machine --url=subsite.example.com --allow-root

# NOT network activation (avoid this)
# wp plugin activate data-machine --network --allow-root
```

Each subsite activation creates its own agent files and database tables.

## Per-Site Agent Files

Each subsite gets independent agent memory files. The paths differ by site:

| Site | Agent Files Path |
|------|-----------------|
| Main site | `wp-content/uploads/datamachine-files/agent/` |
| Subsite (ID 2) | `wp-content/uploads/sites/2/datamachine-files/agent/` |
| Subsite (ID 3) | `wp-content/uploads/sites/3/datamachine-files/agent/` |

Each subsite has its own SOUL.md, USER.md, and MEMORY.md — different agents can have different identities and memories.

## WP-CLI with Multisite

Always use the `--url` flag when running WP-CLI commands on a multisite:

```bash
# Target the main site
wp datamachine flows list --url=example.com --allow-root

# Target a subsite
wp datamachine flows list --url=subsite.example.com --allow-root

# Without --url, WP-CLI defaults to the main site
```

This applies to all `wp datamachine` commands — flows, workspace, memory, etc.

## OpenClaw Configuration

The `opencode.json` (or equivalent config) needs to reference the correct agent file paths for each subsite. If your agent manages multiple subsites, you'll need to account for the different upload paths.

For a single-site agent, point to that site's specific paths:

```json
{
  "prompt": [
    "wp-content/uploads/sites/2/datamachine-files/agent/SOUL.md",
    "wp-content/uploads/sites/2/datamachine-files/agent/USER.md",
    "wp-content/uploads/sites/2/datamachine-files/agent/MEMORY.md"
  ]
}
```

## AI Provider Keys

Data Machine's AI HTTP client stores API keys as a **network-wide option** (`chubes_ai_http_shared_api_keys` via `get_site_option()`). Configure your AI provider keys once — they work across all subsites automatically.

## What's Per-Site vs Network-Wide

| Scope | What |
|-------|------|
| **Per-site** | Agent files (SOUL/USER/MEMORY.md), database tables, flows, pipelines, chat sessions, plugin settings |
| **Network-wide** | AI provider API keys, plugin files (code), agent workspace |

## Known Limitations

- `uninstall.php` does not iterate subsites — if you uninstall Data Machine, chat session tables on subsites may be left behind
- The agent workspace (`/var/lib/datamachine/workspace/`) is shared across all sites on the same server
