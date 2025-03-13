#!/bin/bash
# Enforce SSH Key Authentication Only & Disable Password Login

# Prompt to confirm enabling SSH key authentication only
echo -n "Do you want to enforce SSH key authentication only? (yes/no): "
read CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborting. No changes made."
    exit 0
fi

# Prompt for the allowed SSH user
echo -n "Enter the allowed SSH user: "
read ALLOWED_USER

# Ensure SSH public key authentication is enabled
sed -i 's/^.*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Disable password authentication
sed -i 's/^.*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restrict SSH access to the specified user
echo "AllowUsers $ALLOWED_USER" >> /etc/ssh/sshd_config

# Ensure .ssh directory and authorized_keys exist for the user
USER_HOME=$(eval echo ~$ALLOWED_USER)
mkdir -p "$USER_HOME/.ssh"
touch "$USER_HOME/.ssh/authorized_keys"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys"
chown -R $ALLOWED_USER:$ALLOWED_USER "$USER_HOME/.ssh"

# Prompt for SSH public key
echo -n "Enter the SSH public key for $ALLOWED_USER: "
read SSH_KEY

# Add SSH key to authorized_keys
echo "$SSH_KEY" >> "$USER_HOME/.ssh/authorized_keys"

# Restart SSH service
systemctl restart sshd

echo "SSH has been secured: Only SSH key authentication is allowed for $ALLOWED_USER. Key added successfully."
