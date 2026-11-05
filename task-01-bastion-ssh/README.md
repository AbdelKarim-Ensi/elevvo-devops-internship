# Task 1 - Secure Linux Bastion & systemd

## 1. On your laptop: Ed25519 key
```bash
ssh-keygen -t ed25519 -C "elevvo-bastion" -f ~/.ssh/elevvo_ed25519
ssh-copy-id -i ~/.ssh/elevvo_ed25519.pub USER@VM_IP
ssh -i ~/.ssh/elevvo_ed25519 USER@VM_IP        # must work BEFORE hardening
```

## 2. On the VM: explore + harden
```bash
pwd; ls /; ls /etc /var/log /opt        # filesystem hierarchy
sudo ./harden.sh USER                   # no password auth, no root login
```
Test from another terminal:
```bash
ssh -o PubkeyAuthentication=no USER@VM_IP   # must be refused
ssh root@VM_IP                              # must be refused
```

## 3. systemd web service
```bash
sudo ./deploy_service.sh
sudo systemctl stop webapp  && sudo systemctl start webapp
systemctl is-enabled webapp                 # enabled = starts on boot
journalctl -u webapp -n 20 --no-pager
curl http://127.0.0.1:8080
```

## Bonus: SSH only on Tailscale
```bash
curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up
sudo TAILSCALE_IP=$(tailscale ip -4) ./harden.sh USER
ss -tlnp | grep ':22'                       # only the 100.x address
```
