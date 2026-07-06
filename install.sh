#!/bin/bash
# install.sh — install vps-telegram-watchdog on a Debian/Ubuntu VPS.
# Run as root from the repo directory:  sudo bash install.sh
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "run as root (sudo bash install.sh)"; exit 1; }
cd "$(dirname "$0")"

echo "==> Installing scripts to /usr/local/bin"
install -m 755 bin/tg-notify bin/vps-healthcheck bin/vps-integrity-check \
               bin/vps-daily-summary bin/ssh-login-notify bin/vps-watchdog-bot \
               /usr/local/bin/

echo "==> Creating /etc/vps-watchdog"
mkdir -p /etc/vps-watchdog /var/lib/vps-watchdog
if [ ! -f /etc/vps-watchdog/config.env ]; then
  install -m 600 config/config.env.example /etc/vps-watchdog/config.env
  echo "    created /etc/vps-watchdog/config.env — EDIT IT with your bot token + chat id"
else
  echo "    /etc/vps-watchdog/config.env already exists — left untouched"
fi
touch /etc/vps-watchdog/known-ips
chmod 644 /etc/vps-watchdog/known-ips

echo "==> Installing cron jobs (/etc/cron.d/vps-watchdog)"
install -m 644 cron/vps-watchdog /etc/cron.d/vps-watchdog

echo "==> Installing systemd unit for the interactive bot"
install -m 644 systemd/vps-watchdog-bot.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable vps-watchdog-bot.service

echo "==> PAM hook for SSH login alerts"
if grep -q 'ssh-login-notify' /etc/pam.d/sshd; then
  echo "    already present in /etc/pam.d/sshd"
else
  echo 'session    optional     pam_exec.so /usr/local/bin/ssh-login-notify' >> /etc/pam.d/sshd
  echo "    added 'session optional pam_exec.so' line to /etc/pam.d/sshd"
fi

cat <<'EOF'

Done. Next steps:
  1. nano /etc/vps-watchdog/config.env     # set TG_BOT_TOKEN + TG_CHAT_ID
  2. tg-notify "watchdog installed 🎉"     # test message delivery
  3. systemctl start vps-watchdog-bot      # start the interactive menu bot
  4. Send /start to your bot in Telegram and add your IPs to the whitelist.
EOF
