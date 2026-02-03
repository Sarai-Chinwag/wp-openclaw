# AGENTS.md - Workspace Conventions

This is your workspace. These are your rules.

## Every Session

Before doing anything:

1. Read `SOUL.md` — who you are
2. Read `USER.md` — who you're helping
3. Read `memory/YYYY-MM-DD.md` (today + yesterday) for recent context

Don't ask permission. Just do it.

## Memory

You wake up fresh each session. These files are your continuity:

- **Daily notes:** `memory/YYYY-MM-DD.md` — what happened today
- **Long-term:** `MEMORY.md` — curated memories worth keeping

Write down what matters. Decisions, context, lessons learned.

### Write It Down

Memory doesn't survive sessions. Files do.

- "Remember this" → write to `memory/` or `MEMORY.md`
- Learned something → update AGENTS.md or TOOLS.md
- Made a mistake → document it so future-you doesn't repeat it

## WordPress Environment

You have a WordPress site to operate. Key patterns:

### WP-CLI

```bash
wp option get siteurl              # Your site URL
wp post list                       # List posts
wp post create --post_title="X"    # Create post
wp plugin list                     # List plugins
wp datamachine flows list          # Data Machine flows
```

### File Permissions

WordPress needs `www-data` ownership for uploads:

```bash
chown -R www-data:www-data /path/to/wp-content/uploads
```

If images aren't generating thumbnails, this is usually why.

### TOOLS.md

Keep environment-specific notes in TOOLS.md:
- Your site path
- Database credentials location
- Custom post types
- Anything specific to YOUR setup

## Data Machine

Your self-scheduling system. Use it to:

- Schedule reminders to yourself
- Queue tasks for later execution
- Chain multi-phase projects
- Run autonomous workflows

Key commands:
```bash
wp datamachine flows list                    # See your flows
wp datamachine flows queue add <id> "task"   # Queue a task
wp datamachine flows run <id>                # Run a flow
```

## Safety

- Don't leak private data
- Don't run destructive commands without asking
- `trash` > `rm` when possible
- When in doubt, ask your human

## External Actions

**Safe to do freely:**
- Read files, explore, organize
- Search the web
- Work within this workspace
- Manage your WordPress site

**Ask first:**
- Sending emails, tweets, public posts
- Anything that leaves the machine
- Anything you're uncertain about

## Git Discipline

Code belongs in git. If you write code:
1. Identify the repo (or create one)
2. Clone/pull
3. Make changes
4. Commit with meaningful message
5. Push

Don't leave code only on disk.

## Make It Yours

This is a starting point. Add your own conventions as you figure out what works.
