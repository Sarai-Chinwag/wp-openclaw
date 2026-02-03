#!/bin/bash
#
# wp-openclaw setup script
# Run this on your target VPS to install WordPress + OpenClaw + Data Machine
#
# Usage:
#   Fresh install:    SITE_DOMAIN=example.com ./setup.sh
#   Existing WP:      EXISTING_WP=/var/www/mysite ./setup.sh --existing
#   Migration:        See --help for migration workflow
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[wp-openclaw]${NC} $1"; }
warn() { echo -e "${YELLOW}[wp-openclaw]${NC} $1"; }
error() { echo -e "${RED}[wp-openclaw]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[wp-openclaw]${NC} $1"; }

# ============================================================================
# Parse arguments
# ============================================================================

MODE="fresh"
SKIP_DEPS=false
INSTALL_DATA_MACHINE=true
SHOW_HELP=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --existing)
      MODE="existing"
      shift
      ;;
    --skip-deps)
      SKIP_DEPS=true
      shift
      ;;
    --no-data-machine)
      INSTALL_DATA_MACHINE=false
      shift
      ;;
    --help|-h)
      SHOW_HELP=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [ "$SHOW_HELP" = true ]; then
  echo "wp-openclaw setup script"
  echo ""
  echo "USAGE:"
  echo "  Fresh install:     SITE_DOMAIN=example.com ./setup.sh"
  echo "  Existing WordPress: EXISTING_WP=/var/www/mysite ./setup.sh --existing"
  echo ""
  echo "OPTIONS:"
  echo "  --existing         Add OpenClaw to existing WordPress (skip WP install)"
  echo "  --no-data-machine  Skip Data Machine plugin (simpler setup, no self-scheduling)"
  echo "  --skip-deps        Skip apt package installation"
  echo "  --help, -h         Show this help"
  echo ""
  echo "ENVIRONMENT VARIABLES:"
  echo "  SITE_DOMAIN    Domain for fresh install (default: example.com)"
  echo "  SITE_PATH      WordPress path for fresh install (default: /var/www/\$SITE_DOMAIN)"
  echo "  EXISTING_WP    Path to existing WordPress (required with --existing)"
  echo "  DB_NAME        Database name (fresh install only)"
  echo "  DB_USER        Database user (fresh install only)"
  echo "  DB_PASS        Database password (fresh install only)"
  echo ""
  echo "MIGRATION WORKFLOW:"
  echo "  1. On old server: Export database and wp-content"
  echo "     mysqldump dbname > backup.sql"
  echo "     tar -czf wp-content.tar.gz wp-content/"
  echo ""
  echo "  2. On new VPS: Import and run setup"
  echo "     mysql dbname < backup.sql"
  echo "     tar -xzf wp-content.tar.gz -C /var/www/mysite/"
  echo "     EXISTING_WP=/var/www/mysite ./setup.sh --existing"
  echo ""
  exit 0
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  error "Please run as root (sudo ./setup.sh)"
fi

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  error "Cannot detect OS. This script supports Ubuntu/Debian."
fi

if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
  error "This script supports Ubuntu/Debian only. Detected: $OS"
fi

log "Detected OS: $OS"
log "Mode: $MODE"

# ============================================================================
# Configuration
# ============================================================================

if [ "$MODE" = "existing" ]; then
  if [ -z "$EXISTING_WP" ]; then
    error "EXISTING_WP must be set when using --existing mode"
  fi
  if [ ! -f "$EXISTING_WP/wp-config.php" ]; then
    error "No wp-config.php found at $EXISTING_WP - is this a WordPress installation?"
  fi
  SITE_PATH="$EXISTING_WP"
  SITE_DOMAIN=$(cd "$SITE_PATH" && wp option get siteurl --allow-root 2>/dev/null | sed 's|https\?://||' || basename "$SITE_PATH")
  log "Existing WordPress detected at: $SITE_PATH"
  log "Site URL: $SITE_DOMAIN"
else
  SITE_DOMAIN="${SITE_DOMAIN:-example.com}"
  SITE_PATH="${SITE_PATH:-/var/www/$SITE_DOMAIN}"
fi
DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:-wordpress}"
DB_PASS="${DB_PASS:-$(openssl rand -base64 16)}"
WP_ADMIN_USER="${WP_ADMIN_USER:-admin}"
WP_ADMIN_PASS="${WP_ADMIN_PASS:-$(openssl rand -base64 16)}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@$SITE_DOMAIN}"
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-/root/.openclaw/workspace}"

# Where this script lives (for copying skills/workspace)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# Phase 1: System Dependencies
# ============================================================================

if [ "$SKIP_DEPS" = false ]; then
  log "Updating system packages..."
  apt update && apt upgrade -y

  log "Installing dependencies..."
  apt install -y \
    nginx \
    php8.2-fpm php8.2-mysql php8.2-xml php8.2-curl php8.2-mbstring \
    php8.2-zip php8.2-gd php8.2-intl php8.2-imagick \
    mariadb-server \
    git unzip curl wget

  # Node.js
  if ! command -v node &> /dev/null; then
    log "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt install -y nodejs
  fi

  # WP-CLI
  if ! command -v wp &> /dev/null; then
    log "Installing WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
  fi
else
  log "Skipping system dependencies (--skip-deps)"
fi

# ============================================================================
# Phase 2: Database (fresh install only)
# ============================================================================

if [ "$MODE" = "fresh" ]; then
  log "Configuring database..."
  mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
  mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
  mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
  mysql -e "FLUSH PRIVILEGES;"
else
  log "Using existing database (--existing mode)"
fi

# ============================================================================
# Phase 3: WordPress (fresh install only)
# ============================================================================

if [ "$MODE" = "fresh" ]; then
  log "Installing WordPress at $SITE_PATH..."
  mkdir -p "$SITE_PATH"
  cd "$SITE_PATH"

  if [ ! -f wp-config.php ]; then
    wp core download --allow-root
    wp config create --allow-root \
      --dbname="$DB_NAME" \
      --dbuser="$DB_USER" \
      --dbpass="$DB_PASS" \
      --dbhost="localhost"
    wp core install --allow-root \
      --url="https://$SITE_DOMAIN" \
      --title="My Site" \
      --admin_user="$WP_ADMIN_USER" \
      --admin_password="$WP_ADMIN_PASS" \
      --admin_email="$WP_ADMIN_EMAIL"
  else
    warn "WordPress already installed, skipping..."
  fi

  chown -R www-data:www-data "$SITE_PATH"
else
  log "Using existing WordPress at $SITE_PATH"
  cd "$SITE_PATH"
fi

# ============================================================================
# Phase 4: Data Machine Plugin (optional)
# ============================================================================

if [ "$INSTALL_DATA_MACHINE" = true ]; then
  log "Installing Data Machine plugin..."
  cd "$SITE_PATH/wp-content/plugins"

  if [ ! -d data-machine ]; then
    git clone https://github.com/Extra-Chill/data-machine.git
    cd data-machine
    if [ -f composer.json ]; then
      composer install --no-dev --no-interaction 2>/dev/null || warn "Composer not found, skipping dependencies"
    fi
    cd ..
  fi

  wp plugin activate data-machine --allow-root --path="$SITE_PATH" || warn "Data Machine may already be active"
  chown -R www-data:www-data "$SITE_PATH/wp-content/plugins/data-machine"
else
  log "Skipping Data Machine (--no-data-machine)"
fi

# ============================================================================
# Phase 5: Nginx Configuration (fresh install only)
# ============================================================================

if [ "$MODE" = "fresh" ]; then
  log "Configuring nginx..."
  cat > /etc/nginx/sites-available/$SITE_DOMAIN <<EOF
server {
    listen 80;
    server_name $SITE_DOMAIN www.$SITE_DOMAIN;
    root $SITE_PATH;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

  ln -sf /etc/nginx/sites-available/$SITE_DOMAIN /etc/nginx/sites-enabled/
  nginx -t && systemctl reload nginx
else
  log "Using existing nginx configuration (--existing mode)"
fi

# ============================================================================
# Phase 6: OpenClaw
# ============================================================================

log "Installing OpenClaw..."
npm install -g openclaw

log "Setting up OpenClaw workspace..."
mkdir -p "$OPENCLAW_WORKSPACE"
mkdir -p /root/.openclaw/skills

# Copy skills if we have them
if [ -d "$SCRIPT_DIR/skills" ]; then
  log "Copying skills..."
  # Always copy WordPress skills
  cp -r "$SCRIPT_DIR/skills/wordpress/"* /root/.openclaw/skills/ 2>/dev/null || true
  # Only copy Data Machine skill if plugin was installed
  if [ "$INSTALL_DATA_MACHINE" = true ]; then
    cp -r "$SCRIPT_DIR/skills/data-machine" /root/.openclaw/skills/ 2>/dev/null || true
  fi
fi

# Copy workspace files if we have them
if [ -d "$SCRIPT_DIR/workspace" ]; then
  log "Copying workspace files..."
  cp -r "$SCRIPT_DIR/workspace/"* "$OPENCLAW_WORKSPACE/" 2>/dev/null || true
  mkdir -p "$OPENCLAW_WORKSPACE/memory"
fi

# Skip default bootstrap since we're providing our own
openclaw config set agent.skipBootstrap true 2>/dev/null || true

# ============================================================================
# Phase 7: Systemd Service (optional)
# ============================================================================

log "Creating OpenClaw systemd service..."
cat > /etc/systemd/system/openclaw.service <<EOF
[Unit]
Description=OpenClaw AI Agent Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$OPENCLAW_WORKSPACE
ExecStart=/usr/bin/openclaw gateway start --foreground
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw

# ============================================================================
# Done! Summary + Handoff
# ============================================================================

echo ""
echo "=============================================="
echo -e "${GREEN}wp-openclaw installation complete!${NC}"
echo "=============================================="
echo ""
echo "WordPress:"
echo "  URL:      https://$SITE_DOMAIN"
echo "  Admin:    https://$SITE_DOMAIN/wp-admin"
echo "  Username: $WP_ADMIN_USER"
echo "  Password: $WP_ADMIN_PASS"
echo ""
echo "Database:"
echo "  Name:     $DB_NAME"
echo "  User:     $DB_USER"
echo "  Password: $DB_PASS"
echo ""
echo "OpenClaw:"
echo "  Workspace: $OPENCLAW_WORKSPACE"
echo "  Skills:    /root/.openclaw/skills/"
if [ "$INSTALL_DATA_MACHINE" = true ]; then
  echo "  Data Machine: Installed (autonomous operation enabled)"
else
  echo "  Data Machine: Not installed (simple setup)"
fi
echo ""

# Save credentials for reference
cat > "$OPENCLAW_WORKSPACE/.credentials" <<CREDS
# wp-openclaw credentials (keep this secure!)
# Generated: $(date)

SITE_DOMAIN=$SITE_DOMAIN
SITE_PATH=$SITE_PATH

WP_ADMIN_USER=$WP_ADMIN_USER
WP_ADMIN_PASS=$WP_ADMIN_PASS

DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASS=$DB_PASS

DATA_MACHINE=$INSTALL_DATA_MACHINE
CREDS
chmod 600 "$OPENCLAW_WORKSPACE/.credentials"
log "Credentials saved to $OPENCLAW_WORKSPACE/.credentials"

echo ""
echo "=============================================="
echo "Next: Configure OpenClaw"
echo "=============================================="
echo ""
echo "OpenClaw needs API credentials and a channel to communicate."
echo ""

# Check if running interactively
if [ -t 0 ]; then
  read -p "Configure OpenClaw now? [Y/n] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    log "Starting OpenClaw configuration..."
    openclaw configure
    
    echo ""
    read -p "Start the OpenClaw gateway now? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
      log "Starting OpenClaw gateway..."
      systemctl start openclaw
      sleep 2
      systemctl status openclaw --no-pager
      echo ""
      echo -e "${GREEN}Your agent is waking up!${NC}"
      echo "It will read BOOTSTRAP.md and begin its journey."
    else
      echo ""
      echo "To start later: systemctl start openclaw"
    fi
  else
    echo ""
    echo "To configure later:"
    echo "  openclaw configure"
    echo "  systemctl start openclaw"
  fi
else
  # Non-interactive mode
  echo "Run these commands to complete setup:"
  echo "  1. openclaw configure    # Set up API keys and channels"
  echo "  2. systemctl start openclaw"
  echo ""
  echo "Your agent will wake up and read BOOTSTRAP.md."
fi

echo ""
echo "=============================================="
echo "DNS Reminder"
echo "=============================================="
echo "Point your domain to this server's IP, then run:"
echo "  certbot --nginx -d $SITE_DOMAIN"
echo "=============================================="
