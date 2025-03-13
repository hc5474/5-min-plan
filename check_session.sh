#!/bin/bash
# Check all active user sessions and trace their parent processes

apt install psmisc -y

echo "Active Sessions and Their Parent Processes:"
echo "------------------------------------------------------"

# Get list of active sessions
who | awk '{print $1, $2, $5}' | while read user tty ip; do
    echo "User: $user | TTY: $tty | IP: $ip"
    
    # Get the process tree for the user session
    pids=$(pgrep -u "$user")
    if [[ -n "$pids" ]]; then
        for pid in $pids; do
            pstree -ps "$pid" 2>/dev/null | head -n 1
        done
    else
        echo "No active processes found for user $user"
    fi
    echo "------------------------------------------------------"
done
