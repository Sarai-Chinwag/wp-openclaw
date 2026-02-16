# Architecture

## Directory Structure

```
wp-openclaw/
├── skills/
│   ├── wp-openclaw-setup/     # LOCAL agent only (guides installation)
│   ├── data-machine/          # Copied to OpenClaw (self-scheduling)
│   └── wordpress/             # Copied to OpenClaw (13 WordPress skills)
├── workspace/                 # Copied to OpenClaw workspace
├── docs/                     # Documentation
└── setup.sh                  # Main setup script
```

## Skill Separation

The setup skill stays on your local machine — it's only for deployment. The WordPress and Data Machine skills get copied to the OpenClaw agent on your VPS.

## Components

- **WordPress** — Pre-configured for AI management
- **OpenClaw** — AI agent framework
- **Data Machine** — Self-scheduling execution layer (optional)
- **Agent Skills** — 13 WordPress development skills

## With or Without Data Machine

**Include Data Machine (default) when:**
- Running a content site (blog, news, media)
- You want automated content pipelines
- Agent should orchestrate its own workflows

**Skip Data Machine when:**
- Development-focused setup
- Agent only needs to respond when prompted
- No recurring content workflows
