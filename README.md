# vps-telegram-watchdog

A lightweight, dependency-free VPS monitoring watchdog that reports to
**Telegram** — plus an interactive, menu-driven Telegram bot to control it.

No agents, no SaaS, no pip packages. Just bash + Python 3 stdlib, cron, and
systemd. Built for a single Debian/Ubuntu VPS.

## What you get

**Alerts (push, via cron + PAM):**

| Alert | Trigger | Cadence |
|---|---|---|
| 🚨 Service down | PM2 process or systemd service not running | every 5 min, on state change |
| 💾 Disk near full | `/` above threshold (default 85%) | every 5 min, on state change |
| 🧠 Memory high | above threshold (optional) | every 5 min, on state change |
| 🔐 TLS expiring | Let's Encrypt cert < 14 days | every 5 min, on state change |
| 🚨 Integrity | changes to passwd/shadow/sudoers/sshd_config/crontabs/authorized_keys/nginx sites, listening ports, UFW rules, shell users — with a diff | hourly |
| ✅/🚨 SSH login | every successful login; unknown source IPs flagged | instant (PAM) |
| 📊 Daily summary | uptime, disk, mem, services, fail2ban, SSH stats, nginx codes, TLS, pending updates | 09:00 |

Alerts fire on OK→FAIL **transitions** (with a recovery message on FAIL→OK and
a reminder every 6 h while still failing), so your chat stays high-signal.

**Interactive bot (menu-driven, like a mini app):**

- 📊 **Status** — live uptime, disk, memory, load, services, TLS, fail2ban, sessions
- 🌐 **Whitelist** — view your trusted IPs, add/remove them with buttons
- 👥 **Logins** — recent SSH logins (trusted/unknown flagged) + active sessions
- 🛡 **fail2ban** — currently banned IPs, one-tap unban
- ⚙️ **Services** — PM2 + systemd status; optional one-tap restart (with confirmation)
- 💾 **Disk** — usage + top directory consumers
- ▶️ **Run checks now** — trigger health + integrity checks on demand
- 🔇 **Mute** — silence alerts for 1/6/24 h (menu keeps working)

Only your Telegram chat id can use the bot; all other users are ignored.

## Install

```bash
# 1. Create a bot: message @BotFather in Telegram → /newbot → copy the token.
# 2. Get your chat id: message @userinfobot (or send your bot a message and
#    open https://api.telegram.org/bot<TOKEN>/getUpdates in a browser).

git clone https://github.com/0x2JZ/VPS-health-bot.git
cd VPS-health-bot
sudo bash install.sh

sudo nano /etc/vps-watchdog/config.env    # set TG_BOT_TOKEN and TG_CHAT_ID
tg-notify "watchdog installed 🎉"          # test delivery
sudo systemctl start vps-watchdog-bot     # start the interactive bot
```

Then send `/start` to your bot and add your home/office IPs to the whitelist
so your own logins show as ✅ trusted.

## Configuration

Everything lives in `/etc/vps-watchdog/config.env` (chmod 600). See
[`config/config.env.example`](config/config.env.example) for all options:
disk/memory thresholds, PM2 process list, systemd services, TLS domains,
extra integrity-watched files, re-alert interval, and bot permissions
(`ALLOW_SERVICE_RESTART`, `ALLOW_FAIL2BAN_UNBAN`, extra `TG_ADMIN_IDS`).

The trusted-IP list is a plain file (`/etc/vps-watchdog/known-ips`, one IP per
line) — manage it from the bot menu or by hand.

## Components

```
bin/tg-notify            send a message to your chat (honors mute flag)
bin/vps-healthcheck      5-min health checks with OK/FAIL state tracking
bin/vps-integrity-check  hourly tamper detection with diffs
bin/vps-daily-summary    daily digest
bin/ssh-login-notify     PAM hook: alert on every SSH login
bin/vps-watchdog-bot     interactive Telegram menu bot (systemd service)
```

State lives in `/var/lib/vps-watchdog/`. Uninstall with `sudo bash uninstall.sh`.

## Requirements

- Debian/Ubuntu with bash, curl, python3 (all standard)
- Optional integrations picked up automatically if present: PM2, fail2ban,
  UFW, nginx, certbot/Let's Encrypt

## Security notes

- The config file holds your bot token — the installer creates it `chmod 600`,
  and `.gitignore` blocks committing real config from a repo checkout.
- The bot answers **only** the chat ids you configure; everyone else gets
  silently ignored (callbacks answered "unauthorized").
- Use your **private** chat id, not a group id — in a group, every member of
  the group would be able to control the bot.
- Service restarts from the bot are **off by default**.
- State in `/var/lib/vps-watchdog` is `chmod 700` — the integrity checker
  keeps content snapshots of watched files (including `/etc/shadow`) there.

## License

MIT
