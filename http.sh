#!/bin/bash

echo "[*] Hardening Apache2 on Ubuntu..."

# Disable directory listing
sed -i 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks/' /etc/apache2/apache2.conf

# Disable unnecessary modules
a2dismod autoindex cgi dav dav_fs
systemctl restart apache2

# Prevent Apache from revealing version and OS
echo "ServerTokens Prod" >> /etc/apache2/conf-available/security.conf
echo "ServerSignature Off" >> /etc/apache2/conf-available/security.conf

# Restrict root directory access
echo "<Directory />
    Require all denied
</Directory>" >> /etc/apache2/apache2.conf

# Disable unused HTTP methods
echo "<LimitExcept GET POST HEAD>
    deny from all
</LimitExcept>" >> /etc/apache2/conf-available/security.conf

# Enable basic firewall rules
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Restrict access to Apache config files
echo "<FilesMatch \"^\.ht\">
    Require all denied
</FilesMatch>" >> /etc/apache2/apache2.conf

# Install and enable ModSecurity (WAF)
#apt install -y libapache2-mod-security2
#mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
#sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf
#systemctl restart apache2



echo "[+] Apache2 Hardening Complete!"
