# Task 2 - Nginx Reverse Proxy, UFW, Let's Encrypt

## Prerequisites
- A VM with a public IP and ports 80/443/22 reachable
- A free domain, e.g. DuckDNS (`myapp.duckdns.org` -> VM public IP)
- An app on `127.0.0.1:3000`. Quick test app:
  ```bash
  mkdir -p /tmp/site && echo "Hello Elevvo" > /tmp/site/index.html
  cd /tmp/site && nohup python3 -m http.server 3000 --bind 127.0.0.1 &
  ```

## Run
```bash
sudo DOMAIN=myapp.duckdns.org EMAIL=you@example.com ./setup.sh
```

## Verify (for the demo)
```bash
sudo ufw status verbose                       # default deny incoming
curl -I http://myapp.duckdns.org              # 301 -> https (bonus)
curl -I https://myapp.duckdns.org             # 200, no nginx version in "Server:" (bonus)
sudo certbot certificates
sudo certbot renew --dry-run
```
