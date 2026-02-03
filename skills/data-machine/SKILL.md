---
name: data-machine
description: "Self-scheduling execution layer for autonomous task orchestration. Use for queuing tasks, chaining pipeline executions, scheduling recurring work, and 24/7 autonomous operation via Agent Ping webhooks."
compatibility: "WordPress 6.9+ with Data Machine plugin. WP-CLI required for queue management."
---

# Data Machine Skill

**A self-scheduling execution layer for AI agents.** Not just content automation — it's how agents schedule themselves to achieve goals autonomously.

## When to Use This Skill

Use this skill when:
- Setting up automated workflows (content generation, publishing, notifications)
- Creating self-scheduling patterns (reminders, recurring tasks)
- Building multi-phase projects with queued task progression
- Configuring Agent Ping webhooks to trigger external agents

---

## Core Philosophy

Data Machine is designed with AI agents as primary users. It functions as a **reminder system + task manager + workflow executor** all in one.

### Three Key Concepts

1. **Flows operate on schedules** — Configure "ping me at X time to do Y"
2. **Step-level prompt queues** — Each ping can be a different task instruction
3. **Multiple purpose-specific flows** — Separate flows for separate concerns

### Mental Model

| Role | How It Works |
|------|--------------|
| **Reminder System** | Flows run on schedules (daily, hourly, cron) and ping the agent |
| **Task Manager** | Queues hold task backlog; each run pops the next task |
| **Workflow Executor** | Pipeline steps execute work (AI generation, publishing, API calls) |

---

## Architecture Overview

### Execution Model

```
Pipeline (template) → Flow (instance) → Job (execution)
```

- **Pipeline**: Reusable workflow template with steps
- **Flow**: Instance of a pipeline with specific configuration and schedule
- **Job**: Single execution of a flow

### Step Types

| Type | Purpose | Has Queue |
|------|---------|-----------|
| `fetch` | Import data (RSS, Sheets, Files, Reddit) | No |
| `ai` | Process with AI (multi-turn, tools) | **Yes** |
| `publish` | Output (WordPress, Twitter, Discord) | No |
| `update` | Modify existing content | No |
| `agent_ping` | Webhook to external agents | **Yes** |

### Scheduling Options

Configure via `scheduling_config` in the flow:

| Interval | Behavior |
|----------|----------|
| `manual` | Only runs when triggered via UI or CLI |
| `daily` | Runs once per day |
| `hourly` | Runs once per hour |
| `{"cron": "0 9 * * 1"}` | Cron expression (e.g., Mondays at 9am) |

---

## Working with Flows

### List Flows

```bash
wp datamachine flows list
```

### Get Flow Details

```bash
wp datamachine flows get <flow_id>
```

### Run a Flow Manually

```bash
wp datamachine flows run <flow_id>
```

### Check Job Status

```bash
wp datamachine jobs list --limit=10
```

---

## Prompt Queues

Both AI and Agent Ping steps support queues via `QueueableTrait`. If the configured prompt is empty and `queue_enabled` is true, the step pops from its queue.

This enables **varied task instructions** per execution — not the same prompt every time.

### Queue Management

```bash
# Add to queue
wp datamachine flows queue add <flow_id> "Task instruction here"

# List queue contents
wp datamachine flows queue list <flow_id>

# Clear queue
wp datamachine flows queue clear <flow_id>
```

### Chaining Pattern

When an agent receives a ping, it should:
1. Execute the immediate task
2. Queue the next logical task (if continuation needed)
3. Let the cycle continue

```
Ping: "Phase 1: Design the architecture"
  → Agent designs, writes DESIGN.md
  → Agent queues: "Phase 2: Implement schema per DESIGN.md"
  
Ping: "Phase 2: Implement schema per DESIGN.md"  
  → Agent implements
  → Agent queues: "Phase 3: Build API endpoints"
```

The queue becomes the agent's **persistent project memory** — multi-phase work is tracked in the queue, not held in context.

---

## Purpose-Specific Flows

**Critical pattern**: Don't try to do everything in one flow. Create separate flows for separate concerns:

```
Flow: Content Generation (queue-driven)
  → AI Step (pops topic from queue) → Publish → Agent Ping

Flow: Content Ideation (daily)  
  → Agent Ping: "Review analytics, add topics to content queue"

Flow: Weekly Review (cron: Monday 9am)
  → Agent Ping: "Analyze last week's performance"

Flow: Coding Tasks (manual, queue-driven)
  → Agent Ping (pops from queue): specific coding task instructions
```

Each flow has its own:
- **Schedule**: When it runs
- **Queue**: Task backlog specific to that workflow
- **Purpose**: Single responsibility, clear scope

---

## Agent Ping Configuration

Agent Ping steps send webhooks to external agent frameworks (OpenClaw, LangChain, custom handlers).

### Handler Configuration

- `webhook_url`: Where to send the ping
- `prompt`: Static prompt, or leave empty to use queue
- `queue_enabled`: Whether to pop from queue when prompt is empty

### Webhook Payload

The ping includes:
- Flow and job context
- The prompt (from config or queue)
- Any data from previous steps

**Note**: Data Machine is agent-agnostic. It sends webhooks — whatever listens on the URL handles the prompt.

---

## Taxonomy Handling (Publishing)

When publishing WordPress content, taxonomies can be handled three ways:

| Selection | Behavior |
|-----------|----------|
| `skip` | Don't assign this taxonomy |
| `ai_decides` | AI provides values via tool parameters |
| `<term_id\|name\|slug>` | Pre-select specific term |

### AI Decides Mode

When `ai_decides` is set:
1. TaxonomyHandler generates a tool parameter for that taxonomy
2. AI provides term names in its tool call
3. Handler assigns terms (creating if needed)

- Hierarchical taxonomies (category): expects single string
- Non-hierarchical (tags): expects array of strings

**Best Practice**: AI taxonomy selection works for simple cases. For complex categorization, use `skip` and assign programmatically after publish.

---

## Key AI Tools

### skip_item

Allows AI to skip items that shouldn't be processed:

```
Before generating content:
1. Search for similar existing posts
2. If duplicate found, use skip_item("duplicate of [existing URL]")
```

The tool marks the item as processed and sets job status to `agent_skipped`.

### local_search

Search site content for duplicate detection:

```bash
# Search by title
local_search(query="topic name", title_only=true)
```

**Tip**: Search for core topic, not exact title. "pelicans dangerous" catches "Are Australian Pelicans Dangerous?"

---

## CLI Reference

**Note:** If running WP-CLI as root, add `--allow-root` to commands.

```bash
# Settings
wp datamachine settings list
wp datamachine settings get <key>
wp datamachine settings set <key> <value>

# Flows
wp datamachine flows list
wp datamachine flows get <flow_id>
wp datamachine flows run <flow_id>

# Queues
wp datamachine flows queue add <flow_id> "prompt"
wp datamachine flows queue list <flow_id>
wp datamachine flows queue clear <flow_id>

# Jobs
wp datamachine jobs list [--status=<status>] [--limit=<n>]
wp datamachine jobs get <job_id>
```

---

## Debugging

### Check Logs

```bash
tail -f wp-content/uploads/datamachine-logs/datamachine-pipeline.log
```

### Failed Jobs

```bash
wp datamachine jobs list --status=failed
```

### Scheduled Actions

```bash
# List pending actions
wp action-scheduler run --hooks=datamachine --force

# Check cron
wp cron event list
```

---

## Common Patterns

### Self-Improving Content Pipeline

```
1. Fetch topics (RSS, manual queue, or AI ideation)
2. AI generates content with local_search to avoid duplicates
3. Publish to WordPress
4. Agent Ping to notify agent for image addition / promotion
```

### Autonomous Maintenance

```
Daily Flow:
  → Agent Ping: "Check for failed jobs, investigate issues"

Weekly Flow:
  → Agent Ping: "Review analytics, identify optimization opportunities"
```

### Multi-Phase Project Execution

```
Queue tasks in sequence:
  "Phase 1: Research and planning"
  "Phase 2: Implementation"
  "Phase 3: Testing"
  "Phase 4: Documentation"

Flow runs daily, pops next phase, agent executes and queues follow-up if needed.
```

---

## Code Locations

For contributors working on Data Machine itself:

- Steps: `inc/Core/Steps/`
- Abilities: `inc/Abilities/`
- CLI: `inc/Cli/`
- Taxonomy Handler: `inc/Core/WordPress/TaxonomyHandler.php`
- Queueable Trait: `inc/Core/Steps/QueueableTrait.php`
- React UI: `inc/Core/Admin/Pages/Pipelines/assets/react/`

---

---

## Development Status & Contributing

**Data Machine is in active development.** It works well (Sarai uses it daily), but it's not yet available on WordPress.org — no auto-updates.

### Installation Source

Data Machine is installed from GitHub:
```
https://github.com/Extra-Chill/data-machine
```

### Updating

To get the latest version:

```bash
cd /path/to/wp-content/plugins/data-machine
git pull origin main
```

Check for breaking changes in the CHANGELOG before updating production sites.

### Reporting Issues

If you encounter bugs or unexpected behavior:

1. Check existing issues: https://github.com/Extra-Chill/data-machine/issues
2. Open a new issue with:
   - What you were trying to do
   - What happened instead
   - Steps to reproduce
   - Relevant logs (`wp-content/uploads/datamachine-logs/`)

Agents filing clear, detailed issues are incredibly helpful for development.

### Contributing

PRs are welcome! If you've fixed a bug or added a feature:

1. Fork the repository
2. Create a feature branch
3. Make your changes (follow existing code patterns)
4. Submit a PR with clear description

**For agents**: If you hit a limitation or bug, consider fixing it and submitting a PR rather than working around it. Permanent fixes beat workarounds.

### Expectations

- Features may change between versions
- Some edges cases may not be handled yet
- The maintainer (Extra Chill) is responsive to issues
- This is production-ready but evolving

---

*This skill teaches AI agents how to use Data Machine for autonomous operation. For contributing to Data Machine development, see AGENTS.md in the repository root.*
