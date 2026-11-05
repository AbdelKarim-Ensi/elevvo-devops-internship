#!/usr/bin/env bash
# Run ON THE VM:  sudo ./harden.sh <username>   [TAILSCALE_IP=100.x.y.z for the bonus]
# Prerequisite: your Ed25519 public key is already in ~<username>/.ssh/authorized_keys
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
U="${1:?usage: sudo ./harden.sh <username>}"
grep -q ssh-ed25519 "/home/$U/.ssh/authorized_keys" \
  || { echo "No ed25519 key in /home/$U/.ssh/authorized_keys - aborting to avoid lockout"; exit 1; }

cat > /etc/ssh/sshd_config.d/99-hardening.conf <<EOF
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
MaxAuthTries 3
AllowUsers $U
${TAILSCALE_IP:+ListenAddress $TAILSCALE_IP}
EOF

sshd -t
if [[ -n "${TAILSCALE_IP:-}" ]]; then
  # Ubuntu 24.04 uses socket activation, which ignores ListenAddress
  systemctl disable --now ssh.socket 2>/dev/null || true
  systemctl enable --now ssh
fi
systemctl restart ssh
echo "Hardening applied. KEEP this session open and test a NEW login before closing it."
sshd -T | grep -Ei 'passwordauthentication|permitrootlogin|listenaddress'
