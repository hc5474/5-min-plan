#!/bin/bash
# Check /etc/pam.d for insecure configurations and prompt for reinstalling PAM

echo "Checking /etc/pam.d for insecure configurations..."
if grep -rqE "nullok|pam_permit.so" /etc/pam.d/; then
    echo "Warning: Insecure PAM configuration detected!"
    echo -n "Do you want to reinstall PAM? (yes/no): "
    read CONFIRM
    if [[ "$CONFIRM" == "yes" ]]; then
        echo "Reinstalling PAM..."
        if [[ -f /etc/debian_version ]]; then
            apt update && apt install --reinstall libpam-runtime libpam0g -y
        elif [[ -f /etc/redhat-release ]]; then
            dnf reinstall -y pam
        else
            echo "Unsupported OS. Please reinstall PAM manually."
        fi
        echo "PAM reinstallation complete."
    else
        echo "Skipping PAM reinstallation. Ensure to fix insecure configurations manually."
    fi
else
    echo "PAM configuration appears secure. No action needed."
fi
