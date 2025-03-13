#!/bin/bash
# Change All Passwords for All Users (Cross-Distro Compatible)

# Define a new secure password
NEW_PASSWORD="NewSecurePassword"

# List valid users with a shell
users=$(awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh)/ {print $1}' /etc/passwd)

# Change passwords
for user in $users; do
    echo "$user:$NEW_PASSWORD" | chpasswd
    echo "Password changed for $user"
done
