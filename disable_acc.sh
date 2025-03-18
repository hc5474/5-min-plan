#!/bin/bash
WHITELIST="./whitelist.txt"

# Find the full path of `htop`
BINARY_PATH="$(which htop 2>/dev/null)"

# If `htop` isn't installed, install it (Debian/Ubuntu/Fedora compatible)
if [[ -z "$BINARY_PATH" ]]; then
    echo "htop is not installed. Installing now..."
    if command -v apt &>/dev/null; then
        apt update && apt install -y htop
    elif command -v dnf &>/dev/null; then
        dnf install -y htop
    else
        echo "[-] Error: Package manager not found. Install htop manually."
        exit 1
    fi
    BINARY_PATH="$(which htop 2>/dev/null)"
fi

echo "Available users:"
VALID_USERS=()
INDEX=1
while IFS=: read -r username _ uid _ _ _ shell; do
    # Skip Gray Team users
    if grep -Fxq "$username" "$WHITELIST"; then
        continue
    fi
    # Skip root user
    if [[ "$username" == "root" ]]; then
        continue
    fi

    echo "$INDEX. $username"
    VALID_USERS+=("$username")
    ((INDEX++))
done < /etc/passwd

# Ask user to select accounts to disable
if [[ ${#VALID_USERS[@]} -eq 0 ]]; then
    echo "No accounts available to modify."
    exit 0
fi

echo -n "Enter the numbers of the users to redirect to htop (space-separated): "
read -a SELECTED_USERS

# Modify selected users
for index in "${SELECTED_USERS[@]}"; do
    if [[ "$index" =~ ^[0-9]+$ ]] && [[ "$index" -gt 0 ]] && [[ "$index" -le ${#VALID_USERS[@]} ]]; then
        user="${VALID_USERS[$((index-1))]}"
        
        # Change their shell to execute htop
        usermod -s "$BINARY_PATH" "$user"

        echo "Redirected account: $user -> htop"
    else
        echo "Invalid selection: $index"
    fi
done

echo "User modification process complete!"
