#!/bin/bash

# Detect the package manager
if command -v apt &>/dev/null; then
    PKG_MANAGER="apt"
    UPDATE_CMD="apt update"
    INSTALL_CMD="apt install -y"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    UPDATE_CMD="dnf check-update"
    INSTALL_CMD="dnf install -y"
else
    echo "Unsupported package manager. Please install manually."
    exit 1
fi

# Update package lists
echo "Updating package lists..."
$UPDATE_CMD

# List of packages to install
PACKAGES=(
    curl wget net-tools iproute2 psmisc htop nano vim
    iptables iptables-persistent conntrack ufw fail2ban auditd unattended-upgrades
    libpam-runtime libpam-modules sudo
    openssh-server vsftpd apache2
    syslog-ng tcpdump nmap
)

# Install packages
echo "Installing required packages..."
$INSTALL_CMD "${PACKAGES[@]}"

echo "Installation complete!"
