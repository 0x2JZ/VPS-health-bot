#!/bin/bash
# uninstall.sh — remove vps-telegram-watchdog (keeps /etc/vps-watchdog config).
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run as root"; exit 1; }

systemctl disable --now vps-watchdog-bot.service 2>/dev/null || true
rm -f /etc/systemd/system/vps-watchdog-bot.service
systemctl daemon-reload
rm -f /etc/cron.d/vps-watchdog
rm -f /usr/local/bin/{tg-notify,vps-healthcheck,vps-integrity-check,vps-daily-summary,ssh-login-notify,vps-watchdog-bot}
sed -i '\|pam_exec.so /usr/local/bin/ssh-login-notify|d' /etc/pam.d/sshd
rm -rf /var/lib/vps-watchdog

echo "Removed. Config kept at /etc/vps-watchdog — delete it yourself if unwanted."
