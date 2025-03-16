#!/bin/bash
# Change all SQL user passwords, skipping Gray Team users

GRAYTEAM_WHITELIST="./whitelist.txt"

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

# Change SQL user passwords
echo "Changing SQL user passwords..."
MYSQL_ROOT_USER="root"
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_PASSWORD';" | mysql -u$MYSQL_ROOT_USER -p

echo "Retrieving all SQL users..."
MYSQL_USERS=$(echo "SELECT User, Host FROM mysql.user;" | mysql -u$MYSQL_ROOT_USER -p -N)
while read -r user host; do
    if grep -q "^$user$" "$GRAYTEAM_WHITELIST"; then
        echo "Skipping Gray Team user: $user@$host"
        continue
    fi
    echo "ALTER USER '$user'@'$host' IDENTIFIED BY '$NEW_PASSWORD';" | mysql -u$MYSQL_ROOT_USER -p
    echo "Password changed for SQL user: $user@$host"
done <<< "$MYSQL_USERS"