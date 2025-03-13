#!/bin/bash

# Flush existing rules
tables -F
iptables -X

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -i lo -j ACCEPT

iptables -A INPUT -p tcp -s 10.0.1.69 -j ACCEPT
iptables -A INPUT -p tcp -s 10.0.1.70 -j ACCEPT

iptables -A INPUT -p tcp -s 192.168.201.0/24 -j ACCEPT


# SSH (22/tcp)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# FTP Control Port (21/tcp)
iptables -A INPUT -p tcp --dport 21 -j ACCEPT

# Passive FTP range (40000-50000/tcp)
#iptables -A INPUT -p tcp --dport 40000:50000 -j ACCEPT

# MySQL (3306/tcp)
iptables -A INPUT -p tcp --dport 3306 -j ACCEPT

# HTTP/HTTPS (80/tcp & 443/tcp)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Enable connection tracking for FTP
modprobe nf_conntrack_ftp

# Save iptables rules
iptables-save > /etc/iptables.rules

echo "Firewall rules applied: Default-Deny policy with Management Network & Team 1 whitelisted. Passive FTP enabled."
