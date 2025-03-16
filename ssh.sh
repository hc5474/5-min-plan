#!/bin/bash

echo "[*] Hardening SSH on Fedora..."

# Disable root login
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Allow only the "scoring" user to SSH
#echo "AllowUsers scoring" >> /etc/ssh/sshd_config

# Disable password authentication (use SSH keys only)
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Limit failed login attempts
echo "MaxAuthTries 3" >> /etc/ssh/sshd_config

# Enable SSH key authentication
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Disable X11 forwarding
sed -i 's/^X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config

# Prevent empty passwords
sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# Restart SSH to apply changes
systemctl restart sshd

echo "[+] SSH Hardening Complete!"
