#!/bin/bash
# Backup Configuration Files for Critical Services

BACKUP_ROOT="./backup/service_configs_$(date +%F_%T)"
mkdir -p "$BACKUP_ROOT"

# Backup SSH configuration
if [ -f /etc/ssh/sshd_config ]; then
    mkdir -p "$BACKUP_ROOT/ssh"
    cp /etc/ssh/sshd_config "$BACKUP_ROOT/ssh/sshd_config.bak"
    echo "SSH configuration backed up."
fi

# Backup FTP configuration (vsftpd for Debian)
if [ -f /etc/vsftpd.conf ]; then
    mkdir -p "$BACKUP_ROOT/ftp"
    cp /etc/vsftpd.conf "$BACKUP_ROOT/ftp/vsftpd.conf.bak"
    echo "FTP configuration backed up."
fi

# Backup SQL configuration (MySQL for Debian)
if [ -d /etc/mysql ]; then
    mkdir -p "$BACKUP_ROOT/sql"
    cp -r /etc/mysql "$BACKUP_ROOT/sql/"
    echo "SQL configuration backed up."
fi

# Backup Apache2 configuration (Ubuntu)
if [ -d /etc/apache2 ]; then
    mkdir -p "$BACKUP_ROOT/apache2"
    cp -r /etc/apache2 "$BACKUP_ROOT/apache2/"
    echo "Apache2 configuration backed up."
fi

# List backup files
echo "Backup completed. Files saved in: $BACKUP_ROOT"
