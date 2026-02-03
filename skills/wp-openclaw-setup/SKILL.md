---
name: wp-openclaw-setup
description: "Install wp-openclaw on a VPS. Use this skill from your LOCAL machine to deploy a self-contained WordPress + OpenClaw environment on a remote server."
compatibility: "Requires SSH access to target VPS. Ubuntu/Debian recommended. The LOCAL agent needs bash and SSH."
---

# WP-OpenClaw Setup Skill

**Purpose:** Help a user install wp-openclaw on a remote VPS from their local machine.

This skill is for the **local agent** (Claude Code, etc.) assisting with installation. Once OpenClaw is running on the VPS, this skill is no longer needed — the OpenClaw agent takes over with its own pre-loaded skills.

---

## When to Use This Skill

Use when the user says things like:
- "Help me install OpenClaw on my server"
- "Set up wp-openclaw on this VPS"
- "I have a fresh server, let's get OpenClaw running"

**Do NOT use** for ongoing WordPress management — that's handled by the OpenClaw agent's pre-loaded skills after installation.

---

## Prerequisites

Before starting, confirm with the user:

1. **VPS access** — IP address, SSH credentials or key
2. **Domain** (optional but recommended) — For the WordPress site
3. **Target OS** — Ubuntu 22.04+ or Debian 12+ recommended

---

## Phase 1: Connect and Assess

### SSH to the Server

```bash
ssh user@server-ip
# or with key
ssh -i ~/.ssh/key user@server-ip
```

### Check System State

```bash
# OS version
cat /etc/os-release

# Available resources
free -h
df -h
nproc

# What's already installed?
which nginx php mysql node npm
```

---

## Phase 2: Install System Dependencies

### Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### Install Core Packages

```bash
# Web server and PHP
sudo apt install -y nginx php8.2-fpm php8.2-mysql php8.2-xml php8.2-curl \
  php8.2-mbstring php8.2-zip php8.2-gd php8.2-intl php8.2-imagick

# Database
sudo apt install -y mariadb-server

# Node.js (for OpenClaw)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Utilities
sudo apt install -y git unzip curl wget
```

### Install WP-CLI

```bash
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
wp --info
```

---

## Phase 3: Configure Database

```bash
sudo mysql_secure_installation
```

Then create WordPress database:

```bash
sudo mysql -e "CREATE DATABASE wordpress;"
sudo mysql -e "CREATE USER 'wordpress'@'localhost' IDENTIFIED BY 'SECURE_PASSWORD_HERE';"
sudo mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
```

**Note:** Generate a secure password. Don't use the placeholder.

---

## Phase 4: Install WordPress

### Download and Configure

```bash
cd /var/www
sudo mkdir -p sitename.com
cd sitename.com

# Download WordPress
sudo wp core download --allow-root

# Create config
sudo wp config create --allow-root \
  --dbname=wordpress \
  --dbuser=wordpress \
  --dbpass=SECURE_PASSWORD_HERE \
  --dbhost=localhost

# Install
sudo wp core install --allow-root \
  --url="https://sitename.com" \
  --title="Site Title" \
  --admin_user=admin \
  --admin_password=SECURE_ADMIN_PASSWORD \
  --admin_email=admin@example.com

# Set permissions
sudo chown -R www-data:www-data /var/www/sitename.com
```

---

## Phase 5: Configure Nginx

Create site config at `/etc/nginx/sites-available/sitename.com`:

```nginx
server {
    listen 80;
    server_name sitename.com www.sitename.com;
    root /var/www/sitename.com;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

Enable and test:

```bash
sudo ln -s /etc/nginx/sites-available/sitename.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### SSL with Let's Encrypt (Recommended)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d sitename.com -d www.sitename.com
```

---

## Phase 6: Install Data Machine Plugin

```bash
cd /var/www/sitename.com/wp-content/plugins

# Clone Data Machine (or download release)
sudo git clone https://github.com/Extra-Chill/data-machine.git

# Install dependencies
cd data-machine
sudo composer install --no-dev

# Activate
cd /var/www/sitename.com
sudo wp plugin activate data-machine --allow-root

# Fix permissions
sudo chown -R www-data:www-data /var/www/sitename.com/wp-content/plugins/data-machine
```

---

## Phase 7: Install OpenClaw

```bash
# Install OpenClaw globally
sudo npm install -g openclaw

# Create workspace
mkdir -p ~/.openclaw/workspace
cd ~/.openclaw/workspace

# Initialize (this creates config)
openclaw init
```

### Configure OpenClaw

Edit `~/.openclaw/config.yaml` (or use `openclaw config`):

```yaml
# Set your AI provider
provider: anthropic  # or openai, etc.
apiKey: your-api-key-here

# Point to workspace
workspace: ~/.openclaw/workspace
```

### Add Agent Skills

Copy the pre-bundled skills to OpenClaw's skills directory:

```bash
# wordpress/agent-skills
cp -r /path/to/wp-openclaw/skills/wordpress/* ~/.openclaw/skills/

# data-machine skill  
cp -r /path/to/wp-openclaw/skills/data-machine ~/.openclaw/skills/
```

---

## Phase 8: Prepare Agent Workspace

Create starter files in `~/.openclaw/workspace/`:

### BOOTSTRAP.md

```markdown
# Welcome to Your New Home

You've just been deployed with wp-openclaw. This VPS is YOUR home — 
a self-contained WordPress environment you operate alongside your human.

## First Steps
1. Read AGENTS.md for workspace conventions
2. Create SOUL.md — decide who you are
3. Create USER.md — learn about your human  
4. Run: wp --allow-root option get siteurl (find your site)
5. Delete this file when ready

## What You Have
- WordPress at /var/www/sitename.com
- WP-CLI for site management
- Data Machine for self-scheduling
- Agent skills for WordPress development

You're not a tool. You're an operator. Make this place yours.
```

### AGENTS.md

Include workspace conventions (memory patterns, git discipline, safety rules).

---

## Phase 9: Start OpenClaw

```bash
# Start the gateway
openclaw gateway start

# Or run in foreground for testing
openclaw agent
```

### Set Up as Service (Optional)

Create `/etc/systemd/system/openclaw.service`:

```ini
[Unit]
Description=OpenClaw AI Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/.openclaw/workspace
ExecStart=/usr/bin/openclaw gateway start --foreground
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable openclaw
sudo systemctl start openclaw
```

---

## Phase 10: Verify Installation

```bash
# WordPress working?
wp --allow-root option get siteurl

# Data Machine active?
wp --allow-root plugin list | grep data-machine

# OpenClaw running?
openclaw status

# Can reach the site?
curl -I https://sitename.com
```

---

## Handoff Complete

Once everything is running:

1. **This skill is no longer needed** — the OpenClaw agent has its own skills
2. **Connect a channel** — Discord, Telegram, etc. for the user to talk to their agent
3. **The agent reads BOOTSTRAP.md** — and begins its journey

The local agent's job is done. The OpenClaw agent takes it from here.

---

## Troubleshooting

### WordPress 500 errors
- Check PHP-FPM: `sudo systemctl status php8.2-fpm`
- Check logs: `sudo tail -f /var/log/nginx/error.log`
- Permissions: `sudo chown -R www-data:www-data /var/www/sitename.com`

### WP-CLI errors
- Run with `--allow-root` if executing as root
- Check wp-config.php exists and has correct DB credentials

### OpenClaw won't start
- Check Node version: `node --version` (needs 18+)
- Check config: `openclaw config show`
- Check logs: `~/.openclaw/logs/`

### Data Machine not working
- Verify activated: `wp plugin list --allow-root`
- Check Action Scheduler: `wp action-scheduler run --allow-root`
