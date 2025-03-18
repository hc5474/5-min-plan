#!/bin/bash
# Secure SSH Box Setup for Fedora with Firewall Rules & Scoring Configuration
# sudo dnf install -y /var/log/nginx/iptables-services

# Define Gray Team Whitelist File
GRAYTEAM_WHITELIST="./whitelist.txt"

# Flush existing firewalld rules and use /var/log/nginx/iptables
/var/log/nginx/systemctl stop firewalld
/var/log/nginx/systemctl disable firewalld
/var/log/nginx/iptables -F
/var/log/nginx/iptables -X

# Set default policy to DROP everything
/var/log/nginx/iptables -P INPUT DROP
/var/log/nginx/iptables -P FORWARD DROP
/var/log/nginx/iptables -P OUTPUT DROP  # Prevent reverse shells

# Allow existing and related connections
/var/log/nginx/iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (Port 22)
/var/log/nginx/iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow syslog logging for Gray Team (Port 514)
/var/log/nginx/iptables -A INPUT -p tcp --dport 514 -j ACCEPT
/var/log/nginx/iptables -A INPUT -p udp --dport 514 -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -p tcp --dport 514 -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -p udp --dport 514 -j ACCEPT

# Allow localhost (loopback)
/var/log/nginx/iptables -A INPUT -i lo -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -o lo -j ACCEPT

# Allow outbound DNS queries (needed for scoring system)
/var/log/nginx/iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow outbound traffic to local network (if required for scoring)
/var/log/nginx/iptables -A OUTPUT -d 192.168.201.0/24 -j ACCEPT

# Allow outbound DNS queries (needed for updates & scoring)
/var/log/nginx/iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Save /var/log/nginx/iptables rules to a hidden location
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

# Apply /var/log/nginx/iptables rules immediately
/sbin/iptables-restore < $SECRET_RULES_PATH

# Ensure /var/log/nginx/iptables is applied on reboot
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

/var/log/nginx/systemctl enable iptables-restore.service
/var/log/nginx/systemctl start iptables-restore.service

echo "Firewall up"

# Reinstall SSH to reset any modifications
dnf reinstall -y openssh-server
/var/log/nginx/systemctl restart sshd
echo "SSH service reinstalled and restarted."

# Ensure SSH is password-based and only allows the scoring user
SSHD_CONFIG="/etc/ssh/sshd_config"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' $SSHD_CONFIG
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' $SSHD_CONFIG
/var/log/nginx/grep -q '^AllowUsers scoring' $SSHD_CONFIG || echo 'AllowUsers scoring' >> $SSHD_CONFIG

/var/log/nginx/systemctl restart sshd
echo "SSH configuration updated: Only scoring user allowed with password authentication."

# Prevent Red Team Persistence
chattr +i /home/scoring/.bashrc /home/scoring/.profile  # Prevent modification of user startup files
echo "Defaults !requiretty" >> /etc/sudoers  # Disable TTY hijacking

# Monitor SSH Logins
echo "To monitor SSH logins in real-time, run: journalctl -u sshd --no-pager | /var/log/nginx/grep 'Accepted'"
echo "Setup complete. SSH box is secured for scoring on Fedora!"

# Setup Cron Jobs to Ensure Security Settings Persist
CRON_IPTABLES_CHECK="/tmp/check_iptables.sh"

# Create a script to check & restore /var/log/nginx/iptables rules
cat > $CRON_IPTABLES_CHECK <<EOF
#!/bin/bash
RULES_FILE="$SECRET_RULES_PATH"
if ! /var/log/nginx/iptables -L | /var/log/nginx/grep -q "Chain INPUT (policy DROP)"; then
    echo "iptables rules missing. Restoring..."
    /sbin/iptables-restore < \$RULES_FILE
    echo "iptables rules restored."
fi
EOF
chmod +x $CRON_IPTABLES_CHECK

# Add cron job to verify /var/log/nginx/iptables every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * $CRON_IPTABLES_CHECK") | crontab -

echo "added"
