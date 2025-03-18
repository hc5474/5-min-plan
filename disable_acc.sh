#!/bin/bash
WHITELIST="./whitelist.txt"

# List valid user accounts (excluding system accounts & Gray Team users)
echo "Available users:"
VALID_USERS=()
INDEX=1
while IFS=: read -r username _ uid _ _ _ shell; do
#    if [[ "$uid" -lt 1000 ]] || [[ "$shell" =~ /(\/sbin\/nologin|\/bin\/false)$/ ]]; then
#        continue  # Skip system accounts
#    fi
    if grep -Fxq "$username" "$WHITELIST"; then
        continue  # Skip Gray Team users
    fi
    if [[ "$username" == "root" ]]; then
        continue  # Skip root user
    fi

    echo "$INDEX. $username"
    VALID_USERS+=("$username")
    ((INDEX++))
done < /etc/passwd

# Ask user to select accounts to disable
if [[ ${#VALID_USERS[@]} -eq 0 ]]; then
    echo "No accounts available to disable."
    exit 0
fi

echo -n "Enter the numbers of the users to disable (space-separated): "
read -a SELECTED_USERS

# Disable selected users
for index in "${SELECTED_USERS[@]}"; do
    if [[ "$index" =~ ^[0-9]+$ ]] && [[ "$index" -gt 0 ]] && [[ "$index" -le ${#VALID_USERS[@]} ]]; then
        user="${VALID_USERS[$((index-1))]}"
        usermod -L "$user"
        usermod -s /usr/sbin/nologin "$user"
        echo "Disabled account: $user"
    else
        echo "Invalid selection: $index"
    fi
done

echo "User disabling process complete!"
