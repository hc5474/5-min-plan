#!/bin/bash

echo "[*] Securing MySQL/MariaDB..."

# Disable remote root login
mysql -e "UPDATE mysql.user SET Host='localhost' WHERE User='root' AND Host='%'; FLUSH PRIVILEGES;"

# Remove anonymous users
mysql -e "DELETE FROM mysql.user WHERE User=''; FLUSH PRIVILEGES;"

# Drop the test database
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; FLUSH PRIVILEGES;"

# Create a restricted application user
#mysql -e "CREATE USER 'scoring'@'localhost' IDENTIFIED BY 'SecurePass123!';"
#mysql -e "GRANT SELECT ON assets.* TO 'scoring'@'localhost';"
#mysql -e "FLUSH PRIVILEGES;"

# Restrict non-essential users from remote access
mysql -e "UPDATE mysql.user SET Host='localhost' WHERE User NOT IN ('mysql.sys', 'mysql.session', 'scoring'); FLUSH PRIVILEGES;"

# Disable LOAD DATA LOCAL INFILE
echo "[mysqld]" >> /etc/mysql/my.cnf
echo "local-infile=0" >> /etc/mysql/my.cnf

# Enable logging for auditing
sed -i '/\[mysqld\]/a log_error = /var/log/mysql/error.log' /etc/mysql/my.cnf
sed -i '/\[mysqld\]/a general_log = 1' /etc/mysql/my.cnf
sed -i '/\[mysqld\]/a general_log_file = /var/log/mysql/general.log' /etc/mysql/my.cnf

# Restart MySQL to apply changes
systemctl restart mysql

echo "[+] MySQL hardening complete!"
