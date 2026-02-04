# WP-OpenClaw

**Give your AI agent a home.**

Deploy a WordPress site that your AI agent controls — not just edits, but *runs*. A VPS becomes your agent's headquarters with WP-CLI access, self-scheduling capabilities, and 24/7 autonomous operation.

## How It Works

1. **Add the setup skill to your local coding agent** (Claude Code, Cursor, etc.)
2. **Tell your agent:** "Help me set up wp-openclaw"
3. **Your agent guides you through VPS selection and runs the setup**
4. **Your OpenClaw agent wakes up on the VPS** — reads its bootstrap file and starts operating

That's it. Your local agent handles the deployment. Your OpenClaw agent takes over from there.

## Quick Start

### Recommended: Let Your Agent Do It

Add the `wp-openclaw-setup` skill to your local coding agent:

```
skills/wp-openclaw-setup/
```

Then just ask: "Help me set up wp-openclaw on a new VPS"

Your agent will:
- Help you choose a VPS provider if needed
- SSH to your server and run the setup
- Configure WordPress and OpenClaw
- Prepare the workspace files

### Manual Alternative

If you already have a VPS with SSH access:

```bash
# SSH into your server
ssh root@your-server-ip

# Clone and run setup
git clone https://github.com/Sarai-Chinwag/wp-openclaw.git
cd wp-openclaw
SITE_DOMAIN=yourdomain.com ./setup.sh
openclaw configure
systemctl start openclaw
```

## Setup Options

| Flag | Description |
|------|-------------|
| `--existing` | Add OpenClaw to existing WordPress (skip WP install) |
| `--no-data-machine` | Skip Data Machine for simpler setup (no self-scheduling) |
| `--skip-deps` | Skip apt package installation |
| `--dry-run` | Print commands without executing (for testing) |

### Examples

```bash
# Fresh install with full autonomy
SITE_DOMAIN=example.com ./setup.sh

# Fresh install, simple (no Data Machine)
SITE_DOMAIN=example.com ./setup.sh --no-data-machine

# Existing WordPress with full autonomy
EXISTING_WP=/var/www/mysite ./setup.sh --existing

# Test run without making changes
SITE_DOMAIN=example.com ./setup.sh --dry-run
```

## What Gets Installed

- **WordPress** — Pre-configured for AI management
- **OpenClaw** — The AI agent framework
- **[Data Machine](https://github.com/Extra-Chill/data-machine)** — Self-scheduling execution layer (optional)
- **Agent Skills** — WordPress development skills

### Skill Separation

```
wp-openclaw/
├── skills/
│   ├── wp-openclaw-setup/     # LOCAL agent only (guides installation)
│   ├── data-machine/          # Copied to OpenClaw (self-scheduling)
│   └── wordpress/             # Copied to OpenClaw (13 WordPress skills)
└── workspace/                 # Copied to OpenClaw workspace
```

The setup skill stays on your local machine — it's only for deployment. The WordPress and Data Machine skills get copied to the OpenClaw agent on your VPS.

### WordPress Skills (Pre-loaded)

All 13 official WordPress development skills from [WordPress/agent-skills](https://github.com/WordPress/agent-skills):

| Skill | What it teaches |
|-------|-----------------|
| **wordpress-router** | Classifies WordPress repos and routes to workflows |
| **wp-abilities-api** | Capability-based permissions and REST API auth |
| **wp-block-development** | Gutenberg blocks, block.json, attributes, rendering |
| **wp-block-themes** | theme.json, templates, patterns, style variations |
| **wp-interactivity-api** | data-wp-* directives and stores |
| **wp-performance** | Profiling, caching, database optimization |
| **wp-phpstan** | PHPStan static analysis for WordPress |
| **wp-playground** | Instant local environments |
| **wp-plugin-development** | Plugin architecture, hooks, settings, security |
| **wp-project-triage** | Project type detection and tooling analysis |
| **wp-rest-api** | REST endpoints, schema, auth, response shaping |
| **wp-wpcli-and-ops** | WP-CLI commands, automation, multisite |
| **wpds** | WordPress Design System |

## With or Without Data Machine

**Include Data Machine (default) when:**
- Running a content site (blog, news, media)
- You want automated content pipelines (fetch → process → publish)
- Agent should orchestrate its own workflows

**Skip Data Machine (`--no-data-machine`) when:**
- Development-focused setup (coding assistance, not content)
- Agent only needs to respond when prompted
- No recurring content workflows

Data Machine gives your agent a structured toolkit for content automation — pipelines, queues, and self-orchestrating workflows. Without it, the agent is available for on-demand assistance but lacks the infrastructure for autonomous content operations.

## Requirements

- Linux server (Ubuntu/Debian recommended)
- Node.js 18+
- PHP 8.0+
- MySQL/MariaDB
- nginx or Apache

## Contributing

This project captures lessons learned from autonomous WordPress management. If you discover new patterns, gotchas, or improvements — PRs welcome.

## License

MIT — see [LICENSE](LICENSE)

---

*Built by [Extra Chill](https://extrachill.com) — independent music, independent tools.*
