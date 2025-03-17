#!/bin/bash
# Disable all system users except those in the Gray Team whitelist.

GRAYTEAM_WHITELIST="./whitelist.txt"

# Check if whitelist file exists
if [[ ! -f "$GRAYTEAM_WHITELIST" ]]; then
    echo "Whitelist file $GRAYTEAM_WHITELIST not found. Exiting."
    exit 1
fi

echo "Disabling all non-whitelisted accounts..."

# Iterate through all valid user accounts
while IFS=: read -r username _ _ _ _ _ shell; do
    # Skip system accounts with non-login shells (varies across distros)
    if [[ "$shell" =~ /(\/sbin\/nologin|\/usr\/sbin\/nologin|\/bin\/false)$/ ]]; then
        continue
    fi
    
    # Check if the user is in the whitelist
    if grep -Fxq "$username" "$GRAYTEAM_WHITELIST"; then
        echo "Skipping whitelisted user: $username"
    else
        # Lock the account and set shell to nologin
        usermod -L "$username"
        usermod -s /usr/sbin/nologin "$username" || usermod -s /sbin/nologin "$username"
        echo "Disabled account: $username"
    fi
done < /etc/passwd

# Restart name service caching to apply changes immediately (needed on some distros)
systemctl restart nscd || systemctl restart systemd-resolved || true

echo "Account lockdown complete."
