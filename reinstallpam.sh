#!/bin/bash
# Cross-Distro PAM Force Reinstallation Script

echo "[*] Reinstalling PAM packages..."

# Detect package manager and reinstall PAM
if command -v apt &>/dev/null; then
    apt update && apt install --reinstall -y libpam-runtime libpam-modules
elif command -v dnf &>/dev/null; then
    dnf reinstall -y pam
elif command -v yum &>/dev/null; then
    yum reinstall -y pam
elif command -v zypper &>/dev/null; then
    zypper install --force -y pam
else
    echo "[-] Error: No compatible package manager found. Install PAM manually!"
    exit 1
fi

echo "[+] PAM reinstalled successfully!"
