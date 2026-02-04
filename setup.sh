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

# Execute or print command based on DRY_RUN
run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[dry-run]${NC} $*"
  else
    "$@"
  fi
}

# Write file or print contents based on DRY_RUN
write_file() {
  local file_path="$1"
  local content="$2"
  if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[dry-run]${NC} Would write to $file_path:"
    echo "$content" | sed 's/^/    /'
  else
    echo "$content" > "$file_path"
  fi
}

# ============================================================================
# Parse arguments
# ============================================================================

MODE="fresh"
SKIP_DEPS=false
INSTALL_DATA_MACHINE=true
SHOW_HELP=false
DRY_RUN=false

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
    --dry-run)
      DRY_RUN=true
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
  echo "  --dry-run          Print commands without executing (for testing)"
  echo "  --help, -h         Show this help"
  echo ""
  echo "ENVIRONMENT VARIABLES:"
  echo "  SITE_DOMAIN    Domain for fresh install (default: example.com)"
  echo "  SITE_PATH      WordPress path for fresh install (default: /var/www/\$SITE_DOMAIN)"
  echo "  EXISTING_WP    Path to existing WordPress (required with --existing)"
  echo "  DB_NAME        Database name (fresh install only)"
  echo "  DB_USER        Database user (fresh install only)"
  echo "  DB_PASS        Database password (fresh install only)"
  echo "  NODE_VERSION   Node.js major version to install (default: auto-detect LTS)"
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

# Check if running as root (skip in dry-run mode)
if [ "$DRY_RUN" = false ] && [ "$EUID" -ne 0 ]; then
  error "Please run as root (sudo ./setup.sh)"
fi

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  if [ "$DRY_RUN" = true ]; then
    OS="ubuntu"
    warn "Cannot detect OS (dry-run mode), assuming Ubuntu"
  else
    error "Cannot detect OS. This script supports Ubuntu/Debian."
  fi
fi

if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
  if [ "$DRY_RUN" = true ]; then
    warn "Unsupported OS detected: $OS (continuing in dry-run mode)"
    OS="ubuntu"
  else
    error "This script supports Ubuntu/Debian only. Detected: $OS"
  fi
fi

log "Detected OS: $OS"
log "Mode: $MODE"
if [ "$DRY_RUN" = true ]; then
  log "Dry-run mode: commands will be printed, not executed"
fi

# ============================================================================
# Detect PHP Version
# ============================================================================

detect_php_version() {
  # If PHP is already installed, use that version
  if command -v php &> /dev/null; then
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    log "Detected existing PHP version: $PHP_VERSION"
    return
  fi

  # In dry-run mode, assume a reasonable default
  if [ "$DRY_RUN" = true ]; then
    PHP_VERSION="8.3"
    log "PHP version (dry-run assumed): $PHP_VERSION"
    return
  fi

  # Otherwise, find the best available version in apt
  apt update -qq 2>/dev/null

  # Query apt-cache for available php-fpm packages and extract versions
  # Sort in reverse to prefer newer versions
  PHP_VERSION=$(apt-cache search '^php[0-9]+\.[0-9]+-fpm$' 2>/dev/null | \
    sed -E 's/^php([0-9]+\.[0-9]+)-fpm.*/\1/' | \
    sort -t. -k1,1nr -k2,2nr | \
    head -1)

  if [ -n "$PHP_VERSION" ]; then
    log "Best available PHP version: $PHP_VERSION"
    return
  fi

  # Fallback - let apt decide
  PHP_VERSION=""
  warn "Could not detect PHP version, will use system default"
}

detect_php_version

# ============================================================================
# Configuration
# ============================================================================

if [ "$MODE" = "existing" ]; then
  if [ -z "$EXISTING_WP" ]; then
    error "EXISTING_WP must be set when using --existing mode"
  fi
  if [ "$DRY_RUN" = false ] && [ ! -f "$EXISTING_WP/wp-config.php" ]; then
    error "No wp-config.php found at $EXISTING_WP - is this a WordPress installation?"
  fi
  SITE_PATH="$EXISTING_WP"
  if [ "$DRY_RUN" = true ]; then
    SITE_DOMAIN="${SITE_DOMAIN:-$(basename "$SITE_PATH")}"
    log "Existing WordPress path (dry-run): $SITE_PATH"
    log "Site URL (assumed): $SITE_DOMAIN"
  else
    SITE_DOMAIN=$(cd "$SITE_PATH" && wp option get siteurl --allow-root 2>/dev/null | sed 's|https\?://||' || basename "$SITE_PATH")
    log "Existing WordPress detected at: $SITE_PATH"
    log "Site URL: $SITE_DOMAIN"
  fi
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
  run_cmd apt update
  run_cmd apt upgrade -y

  log "Installing dependencies..."

  # Build PHP package list based on detected version
  if [ -n "$PHP_VERSION" ]; then
    PHP_PACKAGES="php${PHP_VERSION}-fpm php${PHP_VERSION}-mysql php${PHP_VERSION}-xml php${PHP_VERSION}-curl php${PHP_VERSION}-mbstring php${PHP_VERSION}-zip php${PHP_VERSION}-gd php${PHP_VERSION}-intl php${PHP_VERSION}-imagick"
  else
    # Fallback to generic php packages (apt will resolve version)
    PHP_PACKAGES="php-fpm php-mysql php-xml php-curl php-mbstring php-zip php-gd php-intl php-imagick"
  fi

  run_cmd apt install -y nginx $PHP_PACKAGES mariadb-server git unzip curl wget composer

  # Re-detect PHP version after install (in case it wasn't detected before)
  if [ -z "$PHP_VERSION" ] && command -v php &> /dev/null; then
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    log "PHP version after install: $PHP_VERSION"
  fi

  # Node.js
  if ! command -v node &> /dev/null || [ "$DRY_RUN" = true ]; then
    log "Installing Node.js..."

    # Allow override via env var, otherwise detect current LTS
    if [ -z "$NODE_VERSION" ]; then
      # Query NodeSource for current LTS major version
      NODE_VERSION=$(curl -fsSL https://nodejs.org/dist/index.json 2>/dev/null | \
        grep -o '"version":"v[0-9]*' | \
        head -1 | \
        sed 's/"version":"v//')

      # Fallback if detection fails
      if [ -z "$NODE_VERSION" ]; then
        NODE_VERSION="22"
        warn "Could not detect Node.js LTS, using fallback: $NODE_VERSION"
      fi
    fi

    log "Installing Node.js $NODE_VERSION..."
    if [ "$DRY_RUN" = true ]; then
      echo -e "${BLUE}[dry-run]${NC} curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -"
      echo -e "${BLUE}[dry-run]${NC} apt install -y nodejs"
    else
      curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -
      apt install -y nodejs
    fi
  else
    log "Node.js already installed: $(node --version)"
  fi

  # WP-CLI
  if ! command -v wp &> /dev/null || [ "$DRY_RUN" = true ]; then
    log "Installing WP-CLI..."
    run_cmd curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    run_cmd chmod +x wp-cli.phar
    run_cmd mv wp-cli.phar /usr/local/bin/wp
  fi
else
  log "Skipping system dependencies (--skip-deps)"
fi

# ============================================================================
# Phase 2: Database (fresh install only)
# ============================================================================

if [ "$MODE" = "fresh" ]; then
  log "Configuring database..."
  run_cmd mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
  run_cmd mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
  run_cmd mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
  run_cmd mysql -e "FLUSH PRIVILEGES;"
else
  log "Using existing database (--existing mode)"
fi

# ============================================================================
# Phase 3: WordPress (fresh install only)
# ============================================================================

if [ "$MODE" = "fresh" ]; then
  log "Installing WordPress at $SITE_PATH..."
  run_cmd mkdir -p "$SITE_PATH"
  if [ "$DRY_RUN" = false ]; then
    cd "$SITE_PATH"
  else
    echo -e "${BLUE}[dry-run]${NC} cd $SITE_PATH"
  fi

  if [ ! -f wp-config.php ] || [ "$DRY_RUN" = true ]; then
    run_cmd wp core download --allow-root
    run_cmd wp config create --allow-root --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="localhost"
    run_cmd wp core install --allow-root --url="https://$SITE_DOMAIN" --title="My Site" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASS" --admin_email="$WP_ADMIN_EMAIL"
  else
    warn "WordPress already installed, skipping..."
  fi

  run_cmd chown -R www-data:www-data "$SITE_PATH"
else
  log "Using existing WordPress at $SITE_PATH"
  if [ "$DRY_RUN" = false ]; then
    cd "$SITE_PATH"
  else
    echo -e "${BLUE}[dry-run]${NC} cd $SITE_PATH"
  fi
fi

# ============================================================================
# Phase 4: Data Machine Plugin (optional)
# ============================================================================

if [ "$INSTALL_DATA_MACHINE" = true ]; then
  log "Installing Data Machine plugin..."
  if [ "$DRY_RUN" = false ]; then
    cd "$SITE_PATH/wp-content/plugins"
  else
    echo -e "${BLUE}[dry-run]${NC} cd $SITE_PATH/wp-content/plugins"
  fi

  if [ ! -d data-machine ] || [ "$DRY_RUN" = true ]; then
    run_cmd git clone https://github.com/Extra-Chill/data-machine.git
    if [ "$DRY_RUN" = false ]; then
      cd data-machine
    else
      echo -e "${BLUE}[dry-run]${NC} cd data-machine"
    fi
    if [ -f composer.json ] || [ "$DRY_RUN" = true ]; then
      run_cmd env COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --no-interaction || warn "Composer failed, some Data Machine features may not work"
    fi
    if [ "$DRY_RUN" = false ]; then
      cd ..
    fi
  fi

  run_cmd wp plugin activate data-machine --allow-root --path="$SITE_PATH" || warn "Data Machine may already be active"
  run_cmd chown -R www-data:www-data "$SITE_PATH/wp-content/plugins/data-machine"
else
  log "Skipping Data Machine (--no-data-machine)"
fi

# ============================================================================
# Phase 5: Nginx Configuration (fresh install only)
# ============================================================================

if [ "$MODE" = "fresh" ]; then
  log "Configuring nginx..."

  # Determine PHP-FPM socket path
  if [ -n "$PHP_VERSION" ]; then
    PHP_FPM_SOCK="/var/run/php/php${PHP_VERSION}-fpm.sock"
  else
    # Try to find any PHP-FPM socket
    if [ "$DRY_RUN" = false ]; then
      PHP_FPM_SOCK=$(find /var/run/php -name "php*-fpm.sock" 2>/dev/null | head -1)
    fi
    if [ -z "$PHP_FPM_SOCK" ]; then
      PHP_FPM_SOCK="/var/run/php/php-fpm.sock"
      warn "Could not detect PHP-FPM socket, using default: $PHP_FPM_SOCK"
    fi
  fi
  log "Using PHP-FPM socket: $PHP_FPM_SOCK"

  NGINX_CONFIG="server {
    listen 80;
    server_name $SITE_DOMAIN www.$SITE_DOMAIN;
    root $SITE_PATH;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_FPM_SOCK;
    }

    location ~ /\.ht {
        deny all;
    }
}"

  write_file "/etc/nginx/sites-available/$SITE_DOMAIN" "$NGINX_CONFIG"

  run_cmd ln -sf /etc/nginx/sites-available/$SITE_DOMAIN /etc/nginx/sites-enabled/
  if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[dry-run]${NC} nginx -t && systemctl reload nginx"
  else
    nginx -t && systemctl reload nginx
  fi
else
  log "Using existing nginx configuration (--existing mode)"
fi

# ============================================================================
# Phase 6: OpenClaw
# ============================================================================

log "Installing OpenClaw..."
run_cmd npm install -g openclaw

log "Setting up OpenClaw workspace..."
run_cmd mkdir -p "$OPENCLAW_WORKSPACE"
run_cmd mkdir -p /root/.openclaw/skills

# Copy skills if we have them
if [ -d "$SCRIPT_DIR/skills" ]; then
  log "Copying skills..."
  # Always copy WordPress skills
  run_cmd cp -r "$SCRIPT_DIR/skills/wordpress/"* /root/.openclaw/skills/ || true
  # Only copy Data Machine skill if plugin was installed
  if [ "$INSTALL_DATA_MACHINE" = true ]; then
    run_cmd cp -r "$SCRIPT_DIR/skills/data-machine" /root/.openclaw/skills/ || true
  fi
fi

# Copy workspace files if we have them
if [ -d "$SCRIPT_DIR/workspace" ]; then
  log "Copying workspace files..."
  run_cmd cp -r "$SCRIPT_DIR/workspace/"* "$OPENCLAW_WORKSPACE/" || true
  run_cmd mkdir -p "$OPENCLAW_WORKSPACE/memory"
fi

# Skip default bootstrap since we're providing our own
run_cmd openclaw config set agents.defaults.skipBootstrap true || true

# ============================================================================
# Phase 7: Systemd Service (optional)
# ============================================================================

log "Creating OpenClaw systemd service..."

# Find openclaw binary path
if [ "$DRY_RUN" = true ]; then
  OPENCLAW_BIN="/usr/local/bin/openclaw"
  log "Using OpenClaw binary (assumed): $OPENCLAW_BIN"
else
  OPENCLAW_BIN=$(which openclaw 2>/dev/null)
  if [ -z "$OPENCLAW_BIN" ]; then
    # Common fallback locations
    for path in /usr/local/bin/openclaw /usr/bin/openclaw; do
      if [ -x "$path" ]; then
        OPENCLAW_BIN="$path"
        break
      fi
    done
  fi

  if [ -z "$OPENCLAW_BIN" ]; then
    error "Could not find openclaw binary. Is it installed?"
  fi
  log "Using OpenClaw binary: $OPENCLAW_BIN"
fi

SYSTEMD_CONFIG="[Unit]
Description=OpenClaw AI Agent Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$OPENCLAW_WORKSPACE
ExecStart=$OPENCLAW_BIN gateway start --foreground
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target"

write_file "/etc/systemd/system/openclaw.service" "$SYSTEMD_CONFIG"

run_cmd systemctl daemon-reload
run_cmd systemctl enable openclaw

# ============================================================================
# Done! Summary + Handoff
# ============================================================================

echo ""
echo "=============================================="
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}wp-openclaw dry-run complete!${NC}"
  echo "(No changes were made to the system)"
else
  echo -e "${GREEN}wp-openclaw installation complete!${NC}"
fi
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
CREDENTIALS_CONTENT="# wp-openclaw credentials (keep this secure!)
# Generated: $(date)

SITE_DOMAIN=$SITE_DOMAIN
SITE_PATH=$SITE_PATH

WP_ADMIN_USER=$WP_ADMIN_USER
WP_ADMIN_PASS=$WP_ADMIN_PASS

DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASS=$DB_PASS

DATA_MACHINE=$INSTALL_DATA_MACHINE"

write_file "$OPENCLAW_WORKSPACE/.credentials" "$CREDENTIALS_CONTENT"
run_cmd chmod 600 "$OPENCLAW_WORKSPACE/.credentials"
log "Credentials saved to $OPENCLAW_WORKSPACE/.credentials"

echo ""
echo "=============================================="
echo "Next: Configure OpenClaw"
echo "=============================================="
echo ""
echo "OpenClaw needs API credentials and a channel to communicate."
echo ""

# Check if running interactively (skip prompts in dry-run mode)
if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "To configure after running for real:"
  echo "  1. openclaw configure    # Set up API keys and channels"
  echo "  2. systemctl start openclaw"
  echo ""
  echo "Your agent will wake up and read BOOTSTRAP.md."
elif [ -t 0 ]; then
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
