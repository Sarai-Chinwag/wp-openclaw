# WP-OpenClaw Setup Skill

**Purpose:** Guide an AI agent through setting up and configuring WordPress for autonomous AI management via OpenClaw.

## When to Use This Skill

Use this skill when:
- Setting up a new WordPress site for AI management
- Configuring OpenClaw to work with an existing WordPress installation
- Onboarding a new AI agent to manage a WordPress site
- Troubleshooting WordPress + OpenClaw integration issues

---

## Prerequisites

Before starting, ensure you have:

1. **Server access** with sudo/root privileges
2. **WordPress installed** (or ready to install)
3. **OpenClaw running** with access to the WordPress server
4. **WP-CLI installed** (`wp --info` should work)
5. **Data Machine plugin** installed and activated

---

## Phase 1: WordPress Configuration

### 1.1 Verify WP-CLI Access

```bash
# Test WP-CLI works (adjust path to your WordPress installation)
cd /var/www/your-site.com
wp --allow-root option get siteurl
```

If you get a URL back, WP-CLI is working. The `--allow-root` flag is needed when running as root.

### 1.2 File Permissions

WordPress needs proper ownership for media uploads and plugin operations:

```bash
# Set ownership (www-data is typical for Apache/nginx)
chown -R www-data:www-data /var/www/your-site.com/wp-content/uploads
chown -R www-data:www-data /var/www/your-site.com/wp-content/plugins

# Set directory permissions
find /var/www/your-site.com/wp-content -type d -exec chmod 755 {} \;

# Set file permissions
find /var/www/your-site.com/wp-content -type f -exec chmod 644 {} \;
```

**Critical:** Images uploaded via WP-CLI as root won't be processable by WordPress (thumbnails, optimization) unless owned by `www-data`.

### 1.3 Verify Data Machine

```bash
wp --allow-root plugin list | grep data-machine
```

Should show `data-machine` as active. If not:

```bash
wp --allow-root plugin activate data-machine
```

---

## Phase 2: WP-CLI Patterns

These are the core commands you'll use constantly.

### 2.1 Content Operations

```bash
# List recent posts
wp --allow-root post list --post_type=post --posts_per_page=10

# Create a post
wp --allow-root post create --post_title="My Title" --post_content="Content here" --post_status=draft

# Update a post
wp --allow-root post update 123 --post_title="New Title"

# Get post meta
wp --allow-root post meta get 123 _thumbnail_id

# Set featured image
wp --allow-root post meta update 123 _thumbnail_id 456
```

### 2.2 Media Operations

```bash
# Import an image to media library
wp --allow-root media import /path/to/image.jpg --title="Image Title" --alt="Alt text"

# List media
wp --allow-root post list --post_type=attachment --posts_per_page=10

# Get attachment URL
wp --allow-root post get 456 --field=guid
```

**After importing media as root, fix ownership:**

```bash
chown www-data:www-data /var/www/your-site.com/wp-content/uploads/2026/02/*
```

### 2.3 Taxonomy Operations

```bash
# List categories
wp --allow-root term list category

# List tags
wp --allow-root term list post_tag

# Assign category to post
wp --allow-root post term set 123 category "Category Name"

# Assign tags to post
wp --allow-root post term set 123 post_tag "Tag One" "Tag Two"

# Create a term
wp --allow-root term create category "New Category" --description="Description here"
```

### 2.4 Database Queries

```bash
# Run a query
wp --allow-root db query "SELECT ID, post_title FROM wp_posts WHERE post_status='publish' LIMIT 10"

# Export specific data
wp --allow-root db query "SELECT * FROM wp_options WHERE option_name LIKE '%siteurl%'" --skip-column-names
```

**Prefer WP-CLI commands over raw SQL when possible.** Raw SQL bypasses WordPress hooks and validation.

### 2.5 Options and Settings

```bash
# Get an option
wp --allow-root option get blogname

# Set an option
wp --allow-root option update blogname "My Site Name"

# Get all options matching pattern
wp --allow-root option list --search="*mail*"
```

---

## Phase 3: Data Machine Integration

Data Machine provides autonomous content generation and self-scheduling capabilities.

### 3.1 Understanding Data Machine

Data Machine consists of:
- **Flows** — Execution pipelines with steps
- **Queues** — Prompt/topic queues that flows can pull from
- **Steps** — Individual operations (AI generation, handlers, etc.)
- **Agent Ping** — Callback mechanism to notify OpenClaw when work is ready

### 3.2 Checking Flows

```bash
# List all flows
wp --allow-root datamachine flows list

# Get flow details
wp --allow-root datamachine flows get 25

# Check queue for a flow
wp --allow-root datamachine flows queue list 25
```

### 3.3 Queue Management

```bash
# Add topic to queue
wp --allow-root datamachine flows queue add 25 "Topic to write about"

# Remove from queue
wp --allow-root datamachine flows queue remove 25 "Topic to remove"
```

### 3.4 Running Flows

```bash
# Trigger a flow manually
wp --allow-root datamachine flows run 25

# Check job status
wp --allow-root datamachine jobs list --limit=10
```

### 3.5 Agent Ping Setup

Agent Ping allows Data Machine to call back to OpenClaw when work completes. Configure:

1. Set up a webhook endpoint OpenClaw can receive
2. Configure the Agent Ping step in your flow with the webhook URL
3. Include your Discord mention or session identifier in the ping

---

## Phase 4: Common Workflows

### 4.1 Creating a Post with Featured Image

```bash
# 1. Import the image
IMAGE_ID=$(wp --allow-root media import /path/to/image.jpg --porcelain)

# 2. Fix ownership
chown www-data:www-data /var/www/your-site.com/wp-content/uploads/2026/02/*

# 3. Create the post
POST_ID=$(wp --allow-root post create --post_title="Title" --post_content="Content" --post_status=draft --porcelain)

# 4. Set featured image
wp --allow-root post meta update $POST_ID _thumbnail_id $IMAGE_ID

# 5. Assign categories/tags
wp --allow-root post term set $POST_ID category "Category Name"
wp --allow-root post term set $POST_ID post_tag "Tag One" "Tag Two"

# 6. Publish
wp --allow-root post update $POST_ID --post_status=publish
```

### 4.2 Auditing Content

```bash
# Posts without featured images
wp --allow-root db query "
SELECT p.ID, p.post_title 
FROM wp_posts p 
LEFT JOIN wp_postmeta pm ON p.ID = pm.post_id AND pm.meta_key = '_thumbnail_id'
WHERE p.post_type = 'post' 
AND p.post_status = 'publish' 
AND pm.meta_value IS NULL
LIMIT 20
"

# Posts with low word count
wp --allow-root post list --post_type=post --post_status=publish --fields=ID,post_title,post_content --format=json | \
  jq '.[] | select((.post_content | split(" ") | length) < 300)'
```

### 4.3 Bulk Operations

```bash
# Update all posts in a category
for id in $(wp --allow-root post list --category=nature --field=ID); do
  wp --allow-root post meta update $id _some_meta_key "value"
done
```

---

## Phase 5: Security Patterns

When developing WordPress plugins or themes, follow these patterns:

### 5.1 Input Sanitization

Always sanitize user input before using it:

```php
$title = sanitize_text_field( $_POST['title'] );
$content = wp_kses_post( $_POST['content'] );
$email = sanitize_email( $_POST['email'] );
$url = esc_url_raw( $_POST['url'] );
```

### 5.2 Output Escaping

Always escape output before displaying:

```php
echo esc_html( $user_input );
echo esc_attr( $attribute_value );
echo esc_url( $url );
echo wp_kses_post( $html_content );
```

### 5.3 Nonces

Verify requests with nonces:

```php
// Create nonce
wp_nonce_field( 'my_action', 'my_nonce' );

// Verify nonce
if ( ! wp_verify_nonce( $_POST['my_nonce'], 'my_action' ) ) {
    wp_die( 'Security check failed' );
}
```

### 5.4 Capability Checks

Check user capabilities before performing actions:

```php
if ( ! current_user_can( 'edit_posts' ) ) {
    wp_die( 'Unauthorized' );
}
```

### 5.5 Prepared Statements

Use prepared statements for database queries:

```php
global $wpdb;
$results = $wpdb->get_results(
    $wpdb->prepare(
        "SELECT * FROM {$wpdb->posts} WHERE post_author = %d AND post_status = %s",
        $author_id,
        'publish'
    )
);
```

---

## Phase 6: Troubleshooting

### Common Issues

**WP-CLI "Error: This does not appear to be a WordPress installation"**
- Ensure you're in the WordPress root directory
- Check that wp-config.php exists

**Media uploads not generating thumbnails**
- Check file ownership: `ls -la wp-content/uploads/`
- Fix with: `chown -R www-data:www-data wp-content/uploads`

**"Cannot modify header information" errors**
- Usually whitespace before `<?php` in a plugin/theme file
- Check for BOM characters in files

**Data Machine flows not running**
- Check cron: `wp --allow-root cron event list`
- Verify WP-Cron is working or system cron is configured

**Agent Ping not reaching OpenClaw**
- Verify webhook URL is correct
- Check firewall rules
- Test with: `curl -X POST your-webhook-url -d '{"test": true}'`

### Diagnostic Commands

```bash
# WordPress health
wp --allow-root core verify-checksums
wp --allow-root plugin list
wp --allow-root theme list

# Database check
wp --allow-root db check

# Cron status
wp --allow-root cron event list

# PHP errors
tail -f /var/log/php-fpm/error.log  # or your PHP log location
```

---

## Memory Patterns

As an AI managing WordPress, maintain these in your workspace:

### TOOLS.md Should Include:
- WordPress installation path
- Site URL
- Database prefix (usually `wp_`)
- Custom post types and taxonomies
- Important plugin configurations
- Server-specific notes (PHP version, memory limits)

### Regular Maintenance:
- Monitor error logs weekly
- Check for plugin/core updates
- Audit content quality
- Review analytics for top performers
- Clean up draft/orphaned content

---

## Next Steps

Once setup is complete:

1. **Load the WordPress agent skills** for development work:
   - `wp-plugin-development` — Plugin architecture and hooks
   - `wp-block-development` — Gutenberg block development
   - `wp-rest-api` — REST API endpoints
   - `wp-project-triage` — Project analysis

2. **Configure Data Machine flows** for your use case:
   - Content generation pipelines
   - Scheduled maintenance tasks
   - Agent Ping callbacks

3. **Set up monitoring** in your HEARTBEAT.md:
   - Check for failed jobs
   - Monitor traffic/analytics
   - Review error logs

---

*This skill distills lessons learned from autonomous WordPress management. When you encounter new patterns or gotchas, update this skill for future agents.*
