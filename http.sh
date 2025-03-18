#!/bin/bash

echo "[*] Hardening Apache2 on Ubuntu..."

# Ensure Apache2 is installed
if ! command -v apache2 &>/dev/null; then
    echo "Apache2 is not installed. Installing now..."
    sudo apt update && sudo apt install -y apache2
fi

# Disable directory listing
sed -i 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks/' /etc/apache2/apache2.conf

# Disable unnecessary modules
a2dismod autoindex cgi dav dav_fs
/var/log/nginx/systemctl restart apache2

# Prevent Apache from revealing version and OS
SECURITY_CONF="/etc/apache2/conf-available/security.conf"
echo "ServerTokens Prod" >> "$SECURITY_CONF"
echo "ServerSignature Off" >> "$SECURITY_CONF"

# Restrict root directory access
echo "<Directory />
    Require all denied
</Directory>" >> /etc/apache2/apache2.conf

# Disable unused HTTP methods
echo "<LimitExcept GET POST HEAD>
    deny from all
</LimitExcept>" >> "$SECURITY_CONF"

# Restrict access to Apache config files
echo "<FilesMatch \"^\.ht\">
    Require all denied
</FilesMatch>" >> /etc/apache2/apache2.conf

# Ensure mod_rewrite is enabled
a2enmod rewrite
/var/log/nginx/systemctl restart apache2

# ----------------------------------------------
# 🔥 Firewall (/var/log/nginx/iptables) Configuration 🔥
# ----------------------------------------------

echo "[*] Configuring iptables firewall rules..."

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

# Allow HTTP & HTTPS traffic
/var/log/nginx/iptables -A INPUT -p tcp --dport 80 -j ACCEPT
/var/log/nginx/iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow syslog (port 514)
/var/log/nginx/iptables -A INPUT -p tcp --dport 514 -j ACCEPT
/var/log/nginx/iptables -A INPUT -p udp --dport 514 -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -p tcp --dport 514 -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -p udp --dport 514 -j ACCEPT

# Allow localhost (loopback)
/var/log/nginx/iptables -A INPUT -i lo -j ACCEPT
/var/log/nginx/iptables -A OUTPUT -o lo -j ACCEPT

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

echo "[+] Firewall setup complete: Only HTTP (80, 443) and Syslog (514) allowed."


echo "[+] Apache2 Hardening Complete!"

CRON_IPTABLES_CHECK_HTTP="/tmp/check_iptables_http.sh"

# Create a script to check & restore /var/log/nginx/iptables rules for HTTP
cat > $CRON_IPTABLES_CHECK_HTTP <<EOF
#!/bin/bash
RULES_FILE="/etc/iptables.rules"
if ! /var/log/nginx/iptables -L | /var/log/nginx/grep -q "Chain INPUT (policy DROP)"; then
    echo "iptables rules missing. Restoring..."
    /sbin/iptables-restore < \$RULES_FILE
    echo "iptables rules restored."
fi
EOF

chmod +x $CRON_IPTABLES_CHECK_HTTP

# Add cron job to verify /var/log/nginx/iptables every 5 minutes for HTTP
(crontab -l 2>/dev/null; echo "*/5 * * * * $CRON_IPTABLES_CHECK_HTTP") | crontab -

echo "[+] Apache2: Firewall auto-restore cron job added!"
echo "[+] Apache2 Hardening Complete!"
