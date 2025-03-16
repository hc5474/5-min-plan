#!/bin/bash

# Disable anonymous login
sed -i 's/^anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf

# Restrict local users to home directory
sed -i 's/^#chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf
echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf

# Limit FTP users to a specific list
echo "userlist_enable=YES" >> /etc/vsftpd.conf
echo "userlist_file=/etc/vsftpd.user_list" >> /etc/vsftpd.conf
echo "userlist_deny=NO" >> /etc/vsftpd.conf
echo "scoring" >> /etc/vsftpd.user_list

# Set permissions: disable write unless needed
sed -i 's/^write_enable=YES/write_enable=NO/' /etc/vsftpd.conf

# Limit connections per IP
echo "max_clients=10" >> /etc/vsftpd.conf
echo "max_per_ip=3" >> /etc/vsftpd.conf

# Define passive mode ports
echo "pasv_enable=YES" >> /etc/vsftpd.conf
echo "pasv_min_port=30000" >> /etc/vsftpd.conf
echo "pasv_max_port=31000" >> /etc/vsftpd.conf


# Restart FTP service
systemctl restart vsftpd

echo "FTP Hardening Complete!"
