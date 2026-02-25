# Changelog

## Unreleased

### Added
- `--multisite` flag for fresh installs — converts WordPress to multisite (subdirectory by default)
- `--subdomain` flag — use with `--multisite` for subdomain-based multisite (requires wildcard DNS)
- `--no-skills` flag — skip WordPress agent skills installation
- Multisite auto-detection for `--existing` mode (detects subdomain vs subdirectory)
- Per-site Data Machine activation on multisite (uses `--url` flag, not network activation)
- Nginx configs for both subdomain and subdirectory multisite
- Wildcard SSL guidance for subdomain multisite installs

### Changed
- WordPress agent skills now cloned dynamically from [WordPress/agent-skills](https://github.com/WordPress/agent-skills) at install time (always latest version)
- Bundled static skills are no longer used as fallback — if clone fails, agent can install later manually

## [0.1.0] - 2026-02-16
- Initial release
