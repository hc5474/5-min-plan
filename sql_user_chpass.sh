#!/bin/bash
# Change all FTP and SQL user passwords

# Prompt for the new password
echo -n "Enter the new password for all SQL users: "
read -s NEW_PASSWORD
echo

# Confirm password
echo -n "Confirm the new password: "
read -s CONFIRM_PASSWORD
echo

# Check if passwords match
if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi

# Change MySQL/MariaDB user passwords
echo "Changing SQL user passwords..."
MYSQL_ROOT_USER="root"
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_PASSWORD';" | mysql -u$MYSQL_ROOT_USER -p

MYSQL_USERS=$(echo "SELECT User, Host FROM mysql.user WHERE User NOT IN ('root', 'mysql.sys', 'debian-sys-maint');" | mysql -u$MYSQL_ROOT_USER -p -N)
while read -r user host; do
    echo "ALTER USER '$user'@'$host' IDENTIFIED BY '$NEW_PASSWORD';" | mysql -u$MYSQL_ROOT_USER -p
    echo "Password changed for SQL user: $user@$host"
done <<< "$MYSQL_USERS"

echo "All SQL user passwords have been updated successfully."