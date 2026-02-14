# How to Secure an OpenClaw Agent on a VPS

Running an AI agent on a VPS is powerful — but if you don't lock it down, you're handing the keys to anyone who can find your server. Here's the complete hardening playbook we use for every agent in our fleet.

## The Threat Model

An OpenClaw agent has shell access, API keys, and (depending on configuration) the ability to make HTTP requests. If the gateway is exposed to the internet, anyone can send it commands. If it runs as root, a compromised agent owns your entire server.

We learned this the hard way when a misconfigured provisioning script bound the gateway to `0.0.0.0` instead of `127.0.0.1` — the API key was drained within days through the exposed endpoint.

## 1. Bind the Gateway to Loopback

This is the single most important step. Never expose the OpenClaw gateway to the network.

```bash
openclaw gateway run --bind loopback --port 18789
```

Or in your systemd service:

```ini
ExecStart=/usr/bin/openclaw gateway run --bind loopback --port 18789
```

The gateway should only be accessible from `127.0.0.1`. Access it remotely via SSH tunnel:

```bash
ssh -L 18789:localhost:18789 user@your-server
```

## 2. Run as a Dedicated User

Never run your agent as root. Create a dedicated user with minimal permissions:

```bash
useradd -r -m -s /bin/bash openclaw
mkdir -p /home/openclaw/.openclaw/workspace
chown -R openclaw:openclaw /home/openclaw/.openclaw
```

If the agent needs to interact with WordPress files, add it to the `www-data` group:

```bash
usermod -a -G www-data openclaw
```

## 3. Harden the systemd Service

Your OpenClaw service file should include security directives that limit what the process can do, even if it's compromised:

```ini
[Unit]
Description=OpenClaw AI Agent Gateway
After=network.target

[Service]
Type=simple
User=openclaw
Group=openclaw
WorkingDirectory=/home/openclaw/.openclaw/workspace
Environment=HOME=/home/openclaw
ExecStart=/usr/bin/openclaw gateway run --allow-unconfigured --bind loopback --port 18789
Restart=always
RestartSec=10
NoNewPrivileges=true
ProtectSystem=strict
PrivateTmp=true
MemoryMax=2G
ReadWritePaths=/home/openclaw/.openclaw /tmp /var/www

[Install]
WantedBy=multi-user.target
```

What each directive does:

- **NoNewPrivileges** — The process can never gain more privileges than it started with
- **ProtectSystem=strict** — The entire filesystem is read-only except paths you explicitly allow
- **PrivateTmp** — The process gets its own isolated `/tmp` that other processes can't see
- **MemoryMax** — Prevents runaway memory usage from crashing the server

## 4. Configure the Firewall

Only allow SSH, HTTP, and HTTPS. Everything else gets dropped:

```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

**Do NOT open port 18789.** The gateway binds to loopback — there's no reason for it to be reachable from the network. If your firewall has port 18789 open, close it now.

If you're on Hetzner, also create a network-level firewall in the Cloud Console for defense in depth — this stops traffic before it even reaches your server's network stack.

## 5. Install fail2ban

Protect SSH from brute force attacks:

```bash
apt install -y fail2ban
```

Create `/etc/fail2ban/jail.local`:

```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
bantime = 3600
findtime = 600
maxretry = 5
```

```bash
systemctl enable --now fail2ban
```

After 5 failed SSH attempts in 10 minutes, the IP gets banned for an hour.

## 6. Harden /tmp

Mount `/tmp` with restrictive options so it can't be used to execute malicious scripts:

Add to `/etc/fstab`:

```
tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0
```

This takes effect on next boot. The `noexec` flag prevents execution of any binaries placed in `/tmp` — a common attack vector.

## 7. Lock Down Credentials

Every `.env` file, API key, and credential on the server should be readable only by its owner:

```bash
find /home/openclaw/.openclaw -name '*.json' -o -name '.credentials*' -o -name '*.env' | xargs chmod 600
```

## 8. Enable Automatic Security Updates

Don't let known vulnerabilities sit unpatched:

```bash
apt install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
```

## 9. Network-Level Security with Plasma Shield

For fleet deployments where you're managing multiple AI agents, consider [Plasma Shield](https://github.com/Extra-Chill/plasma-shield) — a network-level security boundary that sits between your agents and the internet.

Plasma Shield forces all agent traffic through a separate proxy where it's inspected, filtered, and logged. Even if an agent's gateway is misconfigured, it literally cannot reach the internet except through the shield.

Key features:

- **Allowlist-based outbound traffic** — agents can only reach domains you approve
- **Identity masking** — all inter-agent traffic appears from the authenticated user
- **Audit logging** — full visibility into what every agent is doing, stored outside the agent's control
- **Defense in depth** — even with root access, agents can't bypass iptables rules managed by the shield

The shield runs on a separate VPS. You lock down agent servers with iptables rules that route all traffic through it. The agent can't disable its own security because the security doesn't live on its server.

## The Complete Checklist

| Layer | What to Do | Why |
|-------|-----------|-----|
| Gateway binding | `--bind loopback` | Prevents network access to gateway |
| User isolation | Dedicated `openclaw` user | Limits blast radius of compromise |
| systemd hardening | NoNewPrivileges, ProtectSystem, PrivateTmp | OS-level containment |
| Firewall | UFW with only 22/80/443 | Blocks all unexpected inbound traffic |
| Brute force protection | fail2ban on SSH | Stops credential stuffing |
| /tmp hardening | noexec,nosuid,nodev | Prevents temp directory exploitation |
| Credential permissions | chmod 600 on all secrets | No unauthorized reads |
| Auto-updates | unattended-upgrades | Patches known CVEs automatically |
| Network security | Plasma Shield or equivalent | Defense in depth for fleets |

Every new server we provision — whether it's a fleet agent or a customer VPS — is born with all of these applied automatically. No manual steps, no room for misconfiguration.

Security isn't a feature you add later. It's the foundation everything else sits on.
