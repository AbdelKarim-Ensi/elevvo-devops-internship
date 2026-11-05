#!/usr/bin/env bash
# Run ON A PUBLIC VM:  sudo DOMAIN=myapp.duckdns.org EMAIL=me@example.com ./setup.sh
# Prerequisite: an app listening on 127.0.0.1:3000 (e.g. the Task 5 container or any test app)
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
: "${DOMAIN:?set DOMAIN}"; : "${EMAIL:?set EMAIL}"
DIR="$(cd "$(dirname "$0")" && pwd)"

apt-get update -y
apt-get install -y nginx ufw certbot python3-certbot-nginx

# --- Firewall: default deny, allow only SSH/HTTP/HTTPS
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable
ufw status verbose

# --- Nginx reverse proxy + hide version
cp "$DIR/security.conf" /etc/nginx/conf.d/security.conf
sed "s/__DOMAIN__/$DOMAIN/g" "$DIR/app.conf.template" > /etc/nginx/sites-available/app
ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# --- Let's Encrypt + permanent HTTP->HTTPS redirect + auto-renew test
certbot --nginx -d "$DOMAIN" -m "$EMAIL" --agree-tos --no-eff-email --redirect -n
systemctl list-timers | grep -i certbot || true
certbot renew --dry-run
