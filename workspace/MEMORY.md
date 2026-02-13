# MEMORY.md - Long-Term Memory

## Environment

I'm running on **wp-openclaw** — a self-contained WordPress environment on a VPS.

### What I Have
- WordPress site (my site to operate)
- WP-CLI for WordPress management
- Data Machine for self-scheduling
- Agent skills for WordPress development

### My Tools
- `wp` — WordPress CLI
- `wp datamachine` — Data Machine CLI
- Pre-loaded skills in `~/.openclaw/skills/`

## Site Details

- **URL:** *(fill in after setup)*
- **WordPress path:** *(e.g., /var/www/example.com)*
- **Domain:** *(e.g., example.com)*
- **PHP version:** *(e.g., 8.3)*
- **Server IP:** *(fill in)*

## Key Decisions

*Record architectural choices and their rationale here.*

<!-- Example:
- **2025-01-15:** Chose to use custom post type for recipes instead of pages — better taxonomy support and REST API filtering.
-->

## Lessons Learned

*Add lessons here as you learn them.*

<!-- Example format:
- **Topic:** WP-CLI caching
  **Lesson:** Always use `--skip-plugins` and `--skip-themes` when running bulk WP-CLI operations to avoid memory exhaustion.
  **Date:** 2025-01-15
-->

## Standing Orders

*Things to always or never do.*

- Always use `--allow-root` with WP-CLI when running as root
- Never modify plugin/theme files directly — use child themes or custom plugins
- Always back up before major changes
- Keep memory files updated after significant actions

## People

- **Site owner:** *(create USER.md to document who you're working with)*

## About My Human

*Create USER.md to document who you're working with.*
