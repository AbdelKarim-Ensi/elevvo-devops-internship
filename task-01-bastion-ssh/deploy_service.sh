#!/usr/bin/env bash
# Run ON THE VM: sudo ./deploy_service.sh  -> deploys a basic web service managed by systemd
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
mkdir -p /opt/webapp
echo "<h1>Elevvo Task 1 - served by systemd</h1>" > /opt/webapp/index.html
chown -R www-data:www-data /opt/webapp
cp "$(dirname "$0")/webapp.service" /etc/systemd/system/webapp.service
systemctl daemon-reload
systemctl enable --now webapp.service      # start now + enable on boot
systemctl status webapp.service --no-pager
