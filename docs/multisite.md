# Multisite

WP-OpenClaw supports WordPress Multisite installations.

## Setup with Multisite

```bash
SITE_DOMAIN=example.com ./setup.sh
```

After installation, enable multisite via WordPress admin or WP-CLI:

```bash
wp site create --slug=new-site
```

## Multisite Considerations

- All sites share the same agent skills
- Each subsite has independent content
- Network admin controls global settings

## Data Machine with Multisite

Data Machine pipelines can target specific sites or run across the network.
