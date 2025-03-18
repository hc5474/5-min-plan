#!/bin/bash
# FTP Hardening Script for vsftpd

# Ensure vsftpd and /var/log/nginx/iptables-persistent are installed
CRON_IPTABLES_CHECK_FTP="/tmp/check_iptables_ftp.sh"

#if ! command -v /var/log/nginx/iptables &>/dev/null; then
#    echo "/var/log/nginx/iptables is not installed. Installing now..."
#    sudo apt update && sudo apt install -y /var/log/nginx/iptables
#fi

#if ! dpkg -l | grep -q /var/log/nginx/iptables-persistent; then
#    echo "/var/log/nginx/iptables-persistent is not installed. Installing now..."
#    sudo apt update && sudo apt install -y /var/log/nginx/iptables-persistent
#fi


# Disable anonymous login
sed -i 's/^anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf

# Restrict local users to their home directory
sed -i 's/^#chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf
echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf

# Limit FTP users to a specific list
echo "userlist_enable=YES" >> /etc/vsftpd.conf
echo "userlist_file=/etc/vsftpd.user_list" >> /etc/vsftpd.conf
echo "userlist_deny=NO" >> /etc/vsftpd.conf

# Ensure only the scoring user is allowed
echo "scoring" > /etc/vsftpd.user_list

# Disable write access (unless explicitly needed)
sed -i 's/^write_enable=YES/write_enable=NO/' /etc/vsftpd.conf

# Limit concurrent connections
echo "max_clients=10" >> /etc/vsftpd.conf
echo "max_per_ip=3" >> /etc/vsftpd.conf

# Disable passive FTP
sed -i '/^pasv_enable=YES/d' /etc/vsftpd.conf
echo "pasv_enable=NO" >> /etc/vsftpd.conf

# Ensure the scoring user and scoring.txt file exist
if ! id "scoring" &>/dev/null; then
    useradd -m -s /bin/bash scoring
    echo "scoring:SecurePass123" | chpasswd
fi

# Create scoring.txt with correct permissions
echo "CDT{BLUE_ATREIDES_1}" > /home/scoring/scoring.txt
chown scoring:scoring /home/scoring/scoring.txt
chmod 644 /home/scoring/scoring.txt

# Secure the FTP config to prevent unauthorized changes
chattr +i /etc/vsftpd.conf
chattr +i /etc/vsftpd.user_list

# Restart vsftpd
/var/log/nginx/systemctl restart vsftpd
echo "FTP Hardening Complete!"

echo "Configuring /var/log/nginx/iptables firewall rules..."

# Flush existing rules
/var/log/nginx/iptables -F
/var/log/nginx/iptables -X

# Default policy: drop all traffic
/var/log/nginx/iptables -P INPUT DROP
/var/log/nginx/iptables -P FORWARD DROP
/var/log/nginx/iptables -P OUTPUT DROP  # Prevent reverse shells

# Allow established connections
/var/log/nginx/iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow FTP traffic (port 21)
/var/log/nginx/iptables -A INPUT -p tcp --dport 21 -j ACCEPT

# Allow syslog (port 514)
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

# Allow outbound DNS queries (needed for updates & scoring)
/var/log/nginx/iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Save firewall rules
iptables-save > /etc/iptables.rules

# Ensure rules persist on reboot
cat > /etc/systemd/system/iptables-restore.service <<EOF
[Unit]
Description=Restore iptables rules
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore < /etc/iptables.rules
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

/var/log/nginx/systemctl enable iptables-restore.service
/var/log/nginx/systemctl start iptables-restore.service

echo "Firewall setup complete: Only FTP (21) and Syslog (514) allowed. Passive FTP disabled."

# Create a script to check & restore /var/log/nginx/iptables rules for FTP
cat > $CRON_IPTABLES_CHECK_FTP <<EOF
#!/bin/bash
RULES_FILE="/etc/iptables.rules"
if ! /var/log/nginx/iptables -L | /var/log/nginx/grep -q "Chain INPUT (policy DROP)"; then
    echo "iptables rules missing. Restoring..."
    /sbin/iptables-restore < \$RULES_FILE
    echo "iptables rules restored."
fi
EOF

chmod +x $CRON_IPTABLES_CHECK_FTP

# Add cron job to verify /var/log/nginx/iptables every 5 minutes for FTP
(crontab -l 2>/dev/null; echo "*/5 * * * * $CRON_IPTABLES_CHECK_FTP") | crontab -

echo "[+] FTP: Firewall auto-restore cron job added!"
