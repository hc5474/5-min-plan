#!/bin/bash
# FTP Hardening Script for vsftpd

CRON_IPTABLES_CHECK_FTP="/tmp/check_iptables_ftp.sh"
PASV_MIN_PORT=40000
PASV_MAX_PORT=40010

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

# Enable Passive FTP
sed -i '/^pasv_enable=/d' /etc/vsftpd.conf
echo "pasv_enable=YES" >> /etc/vsftpd.conf
echo "pasv_min_port=$PASV_MIN_PORT" >> /etc/vsftpd.conf
echo "pasv_max_port=$PASV_MAX_PORT" >> /etc/vsftpd.conf

# Ensure the scoring user and scoring.txt file exist
if ! id "scoring" &>/dev/null; then
    useradd -m -s /bin/bash scoring
    echo "scoring:SecurePass123" | chpasswd
fi

echo "CDT{BLUE_ATREIDES_1}" > /home/scoring/scoring.txt
chown scoring:scoring /home/scoring/scoring.txt
chmod 644 /home/scoring/scoring.txt

# Secure vsftpd config files
chattr +i /etc/vsftpd.conf
chattr +i /etc/vsftpd.user_list

# Restart vsftpd
systemctl restart vsftpd
echo "FTP Hardening Complete!"

echo "Configuring iptables firewall rules..."

# Flush existing rules
iptables -F
iptables -X

# Default policy: drop all traffic
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP  # Prevent reverse shells

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow FTP traffic (port 21)
iptables -A INPUT -p tcp --dport 21 -j ACCEPT

# Allow Passive FTP port range
for port in $(seq $PASV_MIN_PORT $PASV_MAX_PORT); do
    iptables -A INPUT -p tcp --dport $port -j ACCEPT
done

# Allow syslog (port 514)
iptables -A INPUT -p tcp --dport 514 -j ACCEPT
iptables -A INPUT -p udp --dport 514 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 514 -j ACCEPT
iptables -A OUTPUT -p udp --dport 514 -j ACCEPT

# Allow localhost (loopback)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow outbound DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow HTTP/HTTPS outbound
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

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

systemctl enable iptables-restore.service
systemctl start iptables-restore.service

echo "Firewall setup complete: Passive FTP enabled on ports $PASV_MIN_PORT-$PASV_MAX_PORT."

# Create a script to check & restore iptables rules for FTP
cat > $CRON_IPTABLES_CHECK_FTP <<EOF
#!/bin/bash
RULES_FILE="/etc/iptables.rules"
if ! iptables -L | grep -q "Chain INPUT (policy DROP)"; then
    echo "iptables rules missing. Restoring..."
    /sbin/iptables-restore < \$RULES_FILE
    echo "iptables rules restored."
fi
EOF

chmod +x $CRON_IPTABLES_CHECK_FTP

# Add cron job to verify iptables every 5 minutes for FTP
(crontab -l 2>/dev/null; echo "*/5 * * * * $CRON_IPTABLES_CHECK_FTP") | crontab -

echo "[+] FTP: Firewall auto-restore cron job added!"
