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

echo "Disabling all user accounts except 'root', 'scoring', and whitelisted users..."

while IFS=: read -r username _ uid _ _ _ shell; do
    # Skip system accounts (UID < 1000, but keep 0 for root explicitly)
    if [[ "$uid" -lt 1000 && "$uid" -ne 0 ]]; then
        continue
    fi

    # Skip root and scoring
    if [[ "$username" == "root" || "$username" == "scoring" ]]; then
        continue
    fi

    # Skip whitelisted users
    if grep -Fxq "$username" "$WHITELIST"; then
        continue
    fi

    # Disable account by changing shell to htop
    usermod -s "$BINARY_PATH" "$username" && \
    echo "Disabled user: $username -> shell set to htop"
done < /etc/passwd

echo "Account disabling process complete."
