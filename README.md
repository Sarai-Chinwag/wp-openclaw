# WP-OpenClaw

**Give your AI agent a home.**

WP-OpenClaw is a self-contained environment for AI agents to autonomously operate WordPress sites. Deploy it on a VPS — any server will do — and your agent gets its own isolated home: a WordPress installation it controls, tools to build with, and the ability to schedule its own work.

## The Concept

A VPS becomes your agent's headquarters:
- **Isolated environment** — The agent's own space, not shared infrastructure
- **Full control** — WP-CLI, file system, database access
- **Self-scheduling** — Data Machine lets the agent set reminders and queue tasks
- **Always available** — 24/7 operation without human intervention

This isn't "AI that can edit WordPress." This is an AI that *runs* a WordPress site.

## What's Included

- **OpenClaw** — The AI agent framework
- **WordPress** — Pre-configured for AI management  
- **Data Machine** — Self-scheduling execution layer (reminder system + task queue + workflow executor)
- **Agent Skills** — WordPress development skills from `wordpress/agent-skills`

```
wp-openclaw/
├── skills/
│   ├── wp-openclaw-setup/        # Installation guide (for local agent)
│   ├── data-machine/             # Self-scheduling patterns
│   └── wordpress/                # ALL official WordPress agent skills (13 skills)
│       ├── wordpress-router/     # Classifies repos, routes to workflows
│       ├── wp-abilities-api/     # Capability-based permissions
│       ├── wp-block-development/ # Gutenberg blocks, block.json
│       ├── wp-block-themes/      # theme.json, templates, patterns
│       ├── wp-interactivity-api/ # data-wp-* directives, stores
│       ├── wp-performance/       # Profiling, caching, optimization
│       ├── wp-phpstan/           # Static analysis for WordPress
│       ├── wp-playground/        # Instant local environments
│       ├── wp-plugin-development/# Plugin architecture, hooks, settings
│       ├── wp-project-triage/    # Project analysis and detection
│       ├── wp-rest-api/          # REST endpoints, schema, auth
│       ├── wp-wpcli-and-ops/     # WP-CLI, automation, multisite
│       └── wpds/                 # WordPress Design System
├── workspace/                    # Starter workspace files
│   ├── BOOTSTRAP.md              # First wake-up guide
│   ├── AGENTS.md                 # Workspace conventions
│   ├── TOOLS.md                  # Environment-specific notes
│   ├── MEMORY.md                 # Starter context
│   └── memory/                   # Daily notes directory
└── README.md
```

## Quick Start

1. **Get a VPS** — Any provider works (Hetzner, DigitalOcean, Linode, etc.)

2. **Run the setup script:**
   ```bash
   # Clone and run
   git clone https://github.com/Sarai-Chinwag/wp-openclaw.git
   cd wp-openclaw
   SITE_DOMAIN=yourdomain.com ./setup.sh
   ```

   Or have your local agent (Claude Code, etc.) use the `wp-openclaw-setup` skill to guide installation — it will ask you questions to determine the right setup.

3. **Configure OpenClaw:**
   ```bash
   openclaw configure  # Set up API keys, channels
   systemctl start openclaw
   ```

4. **Your agent wakes up** — Reads BOOTSTRAP.md, knows what it is, starts operating

## Setup Options

| Flag | Description |
|------|-------------|
| `--existing` | Add OpenClaw to existing WordPress (skip WP install) |
| `--no-data-machine` | Skip Data Machine for simpler setup (no self-scheduling) |
| `--skip-deps` | Skip apt package installation |

### Examples

```bash
# Fresh install with full autonomy
SITE_DOMAIN=example.com ./setup.sh

# Fresh install, simple (no Data Machine)
SITE_DOMAIN=example.com ./setup.sh --no-data-machine

# Existing WordPress with full autonomy
EXISTING_WP=/var/www/mysite ./setup.sh --existing

# Existing WordPress, simple setup
EXISTING_WP=/var/www/mysite ./setup.sh --existing --no-data-machine
```

### Data Machine: Yes or No?

**Include Data Machine when:**
- Running a content site or blog
- You want autonomous operation (agent schedules itself)
- You need task queues, reminders, and workflows

**Skip Data Machine when:**
- Simple personal site
- Agent only helps when asked
- You want minimal complexity

## The Pitch

> Your AI doesn't just respond — it operates.

Most AI + WordPress setups are reactive. The AI waits for commands.

With WP-OpenClaw + Data Machine, your AI can:
- Schedule itself to check on things
- Queue up work and execute autonomously  
- Chain tasks together (publish → optimize → promote)
- Self-improve by learning from results

It's the difference between a tool and an employee.

## Two-Phase Setup

### Phase 1: Installation (Local Agent)

Your local agent (Claude Code, etc.) uses the **wp-openclaw-setup** skill to deploy everything on your VPS:

```
You (local) → "Help me install OpenClaw on my server"
           → Local agent SSHs to VPS
           → Installs WordPress, OpenClaw, Data Machine
           → Prepares workspace with starter files
           → Done. Setup skill no longer needed.
```

### Phase 2: Operation (OpenClaw Agent)

Once running, the OpenClaw agent on the VPS has its own pre-loaded skills:

- **wordpress/agent-skills** — WordPress development patterns
- **data-machine** — Self-scheduling and automation

The setup skill is irrelevant to the running agent. It wakes up, reads its workspace files, and operates.

## Skills

### wp-openclaw-setup (for local agent)
Installation guide for deploying wp-openclaw on a VPS:
- System dependencies (nginx, PHP, MySQL, Node)
- WordPress installation
- Data Machine plugin setup
- OpenClaw configuration
- Workspace preparation

**Used by:** Your local agent during installation  
**Not used by:** The OpenClaw agent after deployment

### data-machine (pre-loaded)
Self-scheduling execution layer:
- Flows and pipelines
- Prompt queues
- Agent Ping callbacks
- Autonomous operation patterns

### wordpress/agent-skills (pre-loaded)
All 13 official WordPress development skills from [WordPress/agent-skills](https://github.com/WordPress/agent-skills):

| Skill | What it teaches |
|-------|-----------------|
| **wordpress-router** | Classifies WordPress repos and routes to the right workflow |
| **wp-abilities-api** | Capability-based permissions and REST API authentication |
| **wp-block-development** | Gutenberg blocks: block.json, attributes, rendering, deprecations |
| **wp-block-themes** | Block themes: theme.json, templates, patterns, style variations |
| **wp-interactivity-api** | Frontend interactivity with data-wp-* directives and stores |
| **wp-performance** | Profiling, caching, database optimization, Server-Timing |
| **wp-phpstan** | PHPStan static analysis for WordPress projects |
| **wp-playground** | WordPress Playground for instant local environments |
| **wp-plugin-development** | Plugin architecture, hooks, settings API, security |
| **wp-project-triage** | Detects project type, tooling, and versions automatically |
| **wp-rest-api** | REST API routes/endpoints, schema, auth, response shaping |
| **wp-wpcli-and-ops** | WP-CLI commands, automation, multisite, search-replace |
| **wpds** | WordPress Design System |

## What's Pre-Loaded

When the OpenClaw agent wakes up, it has:

**Skills:**
- `data-machine` — Self-scheduling, flows, queues, Agent Ping
- All 13 WordPress agent skills (see table above)

**Workspace files:**
- `BOOTSTRAP.md` — First wake-up guide (read once, delete)
- `AGENTS.md` — Workspace conventions and rules
- `TOOLS.md` — Environment-specific notes (starts minimal)
- `MEMORY.md` — Starter context about the environment
- `memory/` — Directory for daily notes

The agent knows from the start that it's in a wp-openclaw environment with a WordPress site to operate.

## Requirements

- Linux server (Ubuntu/Debian recommended)
- Node.js 18+
- PHP 8.0+
- MySQL/MariaDB
- nginx or Apache

## Contributing

This project captures lessons learned from autonomous WordPress management. If you discover new patterns, gotchas, or improvements — PRs welcome.

## License

MIT

---

*Built by [Extra Chill](https://extrachill.com) — independent music, independent tools.*
