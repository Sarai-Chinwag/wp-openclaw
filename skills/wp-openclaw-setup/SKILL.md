---
name: wp-openclaw-setup
description: "Install wp-openclaw on a VPS. Use this skill from your LOCAL machine to deploy a self-contained WordPress + OpenClaw environment on a remote server."
compatibility: "Requires SSH access to target VPS. Ubuntu/Debian recommended. The LOCAL agent needs bash and SSH."
---

# WP-OpenClaw Setup Skill

**Purpose:** Help a user install wp-openclaw on a remote VPS from their local machine.

This skill is for the **local agent** (Claude Code, etc.) assisting with installation. Once OpenClaw is running on the VPS, this skill is no longer needed — the OpenClaw agent takes over with its own pre-loaded skills.

---

## FIRST: Interview the User

**Do NOT proceed with installation until you've asked these questions and gotten answers.**

### Question 1: Installation Type

> "Are you setting up a **fresh WordPress site**, or do you have an **existing WordPress site** you want to add OpenClaw to?"

**Options:**
- **Fresh install** — New VPS, new WordPress site
- **Existing WordPress** — Site already running, just add OpenClaw
- **Migration** — Site exists elsewhere, moving to this VPS

### Question 2: Autonomous Operation

> "Do you want **autonomous operation** capabilities? This includes Data Machine — a self-scheduling system that lets your agent set reminders, queue tasks, and operate 24/7 without human intervention.
>
> - **Yes (recommended for content sites)** — Full autonomy, self-scheduling, proactive operation
> - **No (simpler setup)** — Agent responds when asked, no self-scheduling overhead"

### Question 3: Server Details

> "I'll need some details about your server:
> 1. What's the **server IP address**?
> 2. Do you have **SSH access**? (key or password)
> 3. What **domain** will this site use?"

### Question 4: For Existing WordPress

If they chose existing WordPress:

> "Where is WordPress installed on the server? (e.g., `/var/www/mysite`)"

---

## Build the Command

Based on their answers, construct the appropriate command:

| Scenario | Command |
|----------|---------|
| Fresh + Data Machine | `SITE_DOMAIN=example.com ./setup.sh` |
| Fresh, no Data Machine | `SITE_DOMAIN=example.com ./setup.sh --no-data-machine` |
| Existing + Data Machine | `EXISTING_WP=/var/www/mysite ./setup.sh --existing` |
| Existing, no Data Machine | `EXISTING_WP=/var/www/mysite ./setup.sh --existing --no-data-machine` |

Add `--skip-deps` if nginx, PHP, MySQL, Node are already installed.
Add `--skip-ssl` to skip Let's Encrypt certificate.
Add `--secure` to run the agent as a non-root user.

---

## Confirm Before Proceeding

Before running anything, summarize what you're about to do:

> "Here's the plan:
> - **Server:** 123.45.67.89
> - **Domain:** example.com
> - **Type:** Fresh install
> - **Data Machine:** Yes
> - **Command:** `SITE_DOMAIN=example.com ./setup.sh`
>
> Does this look right?"

Only continue after explicit confirmation.

---

## Run via SSH

```bash
ssh root@<server-ip>
git clone https://github.com/Sarai-Chinwag/wp-openclaw.git
cd wp-openclaw
<constructed command from above>
```

For **migration**, first transfer the database and wp-content:
```bash
# On old server
mysqldump dbname > backup.sql
tar -czf wp-content.tar.gz -C /var/www/oldsite wp-content/
scp backup.sql wp-content.tar.gz root@newserver:/tmp/

# On new server — import, then run setup with --existing
mysql -e "CREATE DATABASE wordpress;" && mysql wordpress < /tmp/backup.sql
mkdir -p /var/www/mysite && tar -xzf /tmp/wp-content.tar.gz -C /var/www/mysite/
```

The script handles everything: PHP (auto-detected), dependencies, WordPress, Data Machine, nginx, SSL, OpenClaw, skills, and workspace files.

---

## Post-Setup Verification

After setup.sh completes, verify:

```bash
# WordPress
wp --allow-root option get siteurl

# Data Machine (if installed)
wp --allow-root plugin list | grep data-machine

# OpenClaw
openclaw gateway status

# Site reachable
curl -I https://yourdomain.com
```

Then complete OpenClaw configuration:
```bash
openclaw configure       # Set up API keys and channels
systemctl start openclaw # Start the agent
```

Credentials are saved to `~/.openclaw/credentials` (chmod 600).

---

## When to Use This Skill

Use when the user says things like:
- "Help me install OpenClaw on my server"
- "Set up wp-openclaw on this VPS"
- "Add OpenClaw to my existing WordPress site"

**Do NOT use** for ongoing WordPress management — that's the OpenClaw agent's job after installation.

---

## Troubleshooting

- **WordPress 500 errors:** Check PHP-FPM status, nginx error log, file permissions
- **WP-CLI errors:** Use `--allow-root`, verify wp-config.php
- **OpenClaw won't start:** Check `node --version` (needs 18+), check `~/.openclaw/logs/`
- **Data Machine not working:** Verify plugin active, run `wp action-scheduler run --allow-root`
