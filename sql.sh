#!/bin/bash

echo "[*] Securing MySQL/MariaDB..."

# Secure MySQL: Disable remote root login
mysql -e "UPDATE mysql.user SET Host='localhost' WHERE User='root' AND Host='%'; FLUSH PRIVILEGES;"

# Remove anonymous users
mysql -e "DELETE FROM mysql.user WHERE User=''; FLUSH PRIVILEGES;"

# Drop the test database
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; FLUSH PRIVILEGES;"

# Ensure only specific users have remote access
mysql -e "UPDATE mysql.user SET Host='localhost' WHERE User NOT IN ('mysql.sys', 'mysql.session', 'scoring'); FLUSH PRIVILEGES;"

# Disable `LOAD DATA LOCAL INFILE` to prevent data import vulnerabilities
MYSQL_CONF="/etc/mysql/my.cnf"
if ! grep -q "local-infile=0" "$MYSQL_CONF"; then
    echo "[mysqld]" >> "$MYSQL_CONF"
    echo "local-infile=0" >> "$MYSQL_CONF"
fi

# Restart MySQL to apply changes
systemctl restart mysql
echo "[+] MySQL hardening complete!"

echo "[*] Configuring iptables firewall rules..."

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

# Allow MySQL traffic (port 3306)
iptables -A INPUT -p tcp --dport 3306 -j ACCEPT

# Allow syslog (port 514)
iptables -A INPUT -p tcp --dport 514 -j ACCEPT
iptables -A INPUT -p udp --dport 514 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 514 -j ACCEPT
iptables -A OUTPUT -p udp --dport 514 -j ACCEPT

# Allow localhost (loopback)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow outbound DNS queries (needed for updates & scoring)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

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

echo "[+] Firewall setup complete: Only MySQL (3306) and Syslog (514) allowed."

echo "[+] MySQL/MariaDB Hardening Complete!"

# Setup Cron Jobs to Ensure Security Settings Persist for MySQL
CRON_IPTABLES_CHECK_SQL="/tmp/check_iptables_sql.sh"
# Create a script to check & restore iptables rules for MySQL
cat > $CRON_IPTABLES_CHECK_SQL <<EOF
#!/bin/bash
RULES_FILE="/etc/iptables.rules"
if ! iptables -L | grep -q "Chain INPUT (policy DROP)"; then
    echo "iptables rules missing. Restoring..."
    /sbin/iptables-restore < \$RULES_FILE
    echo "iptables rules restored."
fi
EOF

chmod +x $CRON_IPTABLES_CHECK_SQL

# Add cron job to verify iptables every 5 minutes for SQL
(crontab -l 2>/dev/null; echo "*/5 * * * * $CRON_IPTABLES_CHECK_SQL") | crontab -

echo "[+] SQL: Firewall auto-restore cron job added!"

