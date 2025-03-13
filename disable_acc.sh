echo "Available users:"
awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh)/ {print NR". "$1}' /etc/passwd

echo -n "Enter the numbers of the users to disable (space-separated): "
read -a selected_users

# Disable selected users
for index in "${selected_users[@]}"; do
    user=$(awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh)/ {print $1}' /etc/passwd | sed -n "${index}p")
    if [ -n "$user" ]; then
        usermod -L "$user"
        usermod -s /usr/sbin/nologin "$user"
        echo "Disabled account: $user"
    else
        echo "Invalid selection: $index"
    fi
done
