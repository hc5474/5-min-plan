#!/bin/bash
# Secure SSH Box Setup for Fedora with Firewall Rules & Scoring Configuration
# sudo dnf install -y iptables-services

# Define Gray Team Whitelist File
GRAYTEAM_WHITELIST="./whitelist.txt"

# Flush existing firewalld rules and use iptables
systemctl stop firewalld
systemctl disable firewalld
iptables -F
iptables -X

# Set default policy to DROP everything
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP  # Prevent reverse shells

# Allow existing and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (Port 22)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow syslog logging for Gray Team (Port 514)
iptables -A INPUT -p tcp --dport 514 -j ACCEPT
iptables -A INPUT -p udp --dport 514 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 514 -j ACCEPT
iptables -A OUTPUT -p udp --dport 514 -j ACCEPT

# Allow localhost (loopback)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow outbound DNS queries (needed for scoring system)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow outbound traffic to local network (if required for scoring)
iptables -A OUTPUT -d 192.168.201.0/24 -j ACCEPT

# Allow outbound DNS queries (needed for updates & scoring)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# Save iptables rules to a hidden location
SECRET_RULES_PATH="/tmp/.hidden_iptables_rules"
cat > $SECRET_RULES_PATH <<EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p tcp --dport 514 -j ACCEPT
-A INPUT -p udp --dport 514 -j ACCEPT
-A OUTPUT -p tcp --dport 514 -j ACCEPT
-A OUTPUT -p udp --dport 514 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
-A OUTPUT -p udp --dport 53 -j ACCEPT
-A OUTPUT -p tcp --dport 53 -j ACCEPT
-A OUTPUT -d 192.168.201.0/24 -j ACCEPT
COMMIT
EOF

# Apply iptables rules immediately
/sbin/iptables-restore < $SECRET_RULES_PATH

# Ensure iptables is applied on reboot
cat > /etc/systemd/system/iptables-restore.service <<EOF
[Unit]
Description=Restore iptables rules
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore $SECRET_RULES_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable iptables-restore.service
systemctl start iptables-restore.service

echo "Firewall up"

# Reinstall SSH to reset any modifications
dnf reinstall -y openssh-server
systemctl restart sshd
echo "SSH service reinstalled and restarted."

# Ensure SSH is password-based and only allows the scoring user
SSHD_CONFIG="/etc/ssh/sshd_config"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' $SSHD_CONFIG
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' $SSHD_CONFIG
grep -q '^AllowUsers scoring' $SSHD_CONFIG || echo 'AllowUsers scoring' >> $SSHD_CONFIG

systemctl restart sshd
echo "SSH configuration updated: Only scoring user allowed with password authentication."

# Prevent Red Team Persistence
chattr +i /home/scoring/.bashrc /home/scoring/.profile  # Prevent modification of user startup files
echo "Defaults !requiretty" >> /etc/sudoers  # Disable TTY hijacking

# Monitor SSH Logins
echo "To monitor SSH logins in real-time, run: journalctl -u sshd --no-pager | grep 'Accepted'"
echo "Setup complete. SSH box is secured for scoring on Fedora!"

# Setup Cron Jobs to Ensure Security Settings Persist
CRON_IPTABLES_CHECK="/tmp/check_iptables.sh"

# Create a script to check & restore iptables rules
cat > $CRON_IPTABLES_CHECK <<EOF
#!/bin/bash
RULES_FILE="$SECRET_RULES_PATH"
if ! iptables -L | grep -q "Chain INPUT (policy DROP)"; then
    echo "iptables rules missing. Restoring..."
    /sbin/iptables-restore < \$RULES_FILE
    echo "iptables rules restored."
fi
EOF
chmod +x $CRON_IPTABLES_CHECK

# Add cron job to verify iptables every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * $CRON_IPTABLES_CHECK") | crontab -

echo "added"
