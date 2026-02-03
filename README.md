# WP-OpenClaw

**AI-managed WordPress, out of the box.**

WP-OpenClaw bundles everything an AI agent needs to autonomously operate a WordPress site:

- **OpenClaw** — The AI agent framework
- **WordPress** — Pre-configured for AI management
- **Data Machine** — Self-scheduling execution layer for autonomous operation
- **Agent Skills** — WordPress development skills from `wordpress/agent-skills`

## What's Included

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

1. Deploy the stack (Docker, manual install, or your preferred method)
2. Point your AI agent at the `wp-openclaw-setup` skill
3. The agent follows the skill to configure everything
4. Start building

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
