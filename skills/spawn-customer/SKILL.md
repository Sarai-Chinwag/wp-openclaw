# Spawn Customer Skill

This skill enables interaction with the Spawn control plane from customer instances.

## Overview

Spawn customers run their own AI agent on a dedicated VPS. This skill allows the agent to:
- Check account status (credits, usage, billing mode)
- Switch between managed credits and BYOK (Bring Your Own Key)
- Get current model information

## Control Plane

The Spawn control plane is at: `https://saraichinwag.com`

All API calls authenticate by server IP - the control plane looks up which customer owns the VPS making the request.

## Getting Your Server IP

```bash
# Get public IP
curl -s https://api.ipify.org
```

## Abilities

### Check Account Status

Get current billing mode, credit balance, usage, and model info.

```bash
SERVER_IP=$(curl -s https://api.ipify.org)
curl -s "https://saraichinwag.com/wp-json/spawn/v1/agent/status?ip=${SERVER_IP}"
```

Response:
```json
{
  "customer_id": 123,
  "tier": "starter",
  "billing_mode": "managed",
  "credit_balance": 4.50,
  "included_credits": 5.0,
  "model": {
    "provider": "Anthropic",
    "name": "Claude",
    "tier": "Opus",
    "version": "4.6",
    "display": "Claude Opus 4.6"
  },
  "usage": {
    "credits_used": 0.50,
    "requests_count": 15,
    "tokens_input": 25000,
    "tokens_output": 8000
  },
  "dashboard_url": "https://saraichinwag.com/spawn/dashboard/"
}
```

### Switch Billing Mode

Switch between managed credits (billed through Spawn) and BYOK (use your own API key).

**Switch to BYOK:**
```bash
SERVER_IP=$(curl -s https://api.ipify.org)
curl -s -X POST "https://saraichinwag.com/wp-json/spawn/v1/agent/billing-mode" \
  -H "Content-Type: application/json" \
  -d "{\"ip\": \"${SERVER_IP}\", \"billing_mode\": \"byok\"}"
```

**Switch to Managed:**
```bash
SERVER_IP=$(curl -s https://api.ipify.org)
curl -s -X POST "https://saraichinwag.com/wp-json/spawn/v1/agent/billing-mode" \
  -H "Content-Type: application/json" \
  -d "{\"ip\": \"${SERVER_IP}\", \"billing_mode\": \"managed\"}"
```

Response:
```json
{
  "success": true,
  "billing_mode": "byok",
  "message": "Switched to Bring Your Own Key mode. You will be billed directly by your AI provider."
}
```

## When to Use

**User asks about billing/credits:**
- "How many credits do I have?" → Check status
- "What's my usage this month?" → Check status
- "What model am I using?" → Check status

**User wants to use their own API key:**
- "I want to use my own Anthropic key" → Switch to BYOK
- "Use my API key instead" → Switch to BYOK

**User wants managed billing:**
- "Switch back to Spawn credits" → Switch to managed
- "I don't want to manage my own key" → Switch to managed

## After Switching to BYOK

When switching to BYOK, help the user configure their API key in OpenClaw:

1. Get their Anthropic API key from https://console.anthropic.com/
2. Update OpenClaw config:
   ```bash
   # Edit ~/.openclaw/config.yaml
   # Set anthropicApiKey: sk-ant-...
   ```
3. Restart OpenClaw gateway

## Notes

- Managed mode: Usage is tracked and deducted from credit balance
- BYOK mode: Usage is billed directly by Anthropic, not tracked by Spawn
- The control plane always knows the current billing mode
- Model info reflects what managed customers use (BYOK customers configure their own)
