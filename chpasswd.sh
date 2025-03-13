#!/bin/bash
echo -n "Enter the new password: "
read -s NEW_PASSWORD
echo

echo -n "Confirm the new password: "
read -s CONFIRM_PASSWORD
echo

if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi

users=$(awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh)/ {print $1}' /etc/passwd)

for user in $users; do
    echo "$user:$NEW_PASSWORD" | chpasswd
    if [ $? -eq 0 ]; then
        echo "Password successfully changed for $user"
    else
        echo "Failed to change password for $user"
    fi
done