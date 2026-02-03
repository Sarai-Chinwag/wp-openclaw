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
│   ├── wp-openclaw-setup/     # Setup guide for AI agents
│   ├── data-machine/          # How to use Data Machine
│   └── wordpress/             # Official WordPress agent skills
│       ├── wp-plugin-development/
│       ├── wp-block-development/
│       ├── wp-rest-api/
│       └── wp-project-triage/
├── wordpress/                  # WordPress with Data Machine plugin
└── README.md
```

## Quick Start

1. **Get a VPS** — Any provider works (Hetzner, DigitalOcean, Linode, etc.)
2. **Deploy WP-OpenClaw** — Run the installer or use Docker
3. **Point your agent at the setup skill** — It configures everything
4. **Your agent has a home** — Watch it operate

## The Pitch

> Your AI doesn't just respond — it operates.

Most AI + WordPress setups are reactive. The AI waits for commands.

With WP-OpenClaw + Data Machine, your AI can:
- Schedule itself to check on things
- Queue up work and execute autonomously  
- Chain tasks together (publish → optimize → promote)
- Self-improve by learning from results

It's the difference between a tool and an employee.

## Skills

### wp-openclaw-setup
Teaches an AI agent how to configure WordPress for AI management. Covers:
- WP-CLI patterns
- File permissions
- Data Machine integration
- Security patterns
- Common workflows
- Troubleshooting

### data-machine
How to use Data Machine once it's running:
- Creating flows and pipelines
- Queue management
- Agent Ping callbacks
- Content automation patterns

### wordpress/agent-skills
Official WordPress development skills:
- **wp-plugin-development** — Plugin architecture, hooks, settings API
- **wp-block-development** — Gutenberg blocks, block.json
- **wp-rest-api** — REST endpoints, schema, authentication
- **wp-project-triage** — Project analysis and detection

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
