#!/bin/bash
WHITELIST="./whitelist.txt"

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

echo "Changing passwords..."
ALL_USERS=$(awk -F: '$3 >= 1000 {print $1}' /etc/passwd)
for user in $ALL_USERS; do
    if grep -q "^$user$" "$WHITELIST"; then
        echo "Skipping Gray Team user: $user"
        continue
    fi
    if id "$user" &>/dev/null; then
        echo "$user:$NEW_PASSWORD" | chpasswd
        echo "Password changed for user: $user"
    fi
done

echo "root:$NEW_PASSWORD" | sudo chpasswd
echo "Password changed for user: $user"
