# Setup Guide

## Quick Start

### Recommended: Let Your Agent Do It

1. Add the `wp-openclaw-setup` skill to your local coding agent
2. Tell your agent: "Help me set up wp-openclaw"
3. Your agent guides you through VPS selection and runs the setup

### Manual Alternative

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
| `--no-data-machine` | Skip Data Machine for simpler setup |
| `--skip-deps` | Skip apt package installation |
| `--dry-run` | Print commands without executing |

## Examples

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

## Requirements

- Linux server (Ubuntu/Debian recommended)
- Node.js 18+
- PHP 8.0+
- MySQL/MariaDB
- nginx or Apache
