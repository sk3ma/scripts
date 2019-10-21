#!/bin/bash

# Verifying Root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root, exiting."
    exit 1
fi
# Apache Installation
apache() {
    echo "Installing Apache"
    sudo apt update
    sudo apt install apache2 apache2-utils libapache2-mod-php7.2 -y
}
# PHP Installation
php() {
    echo "Installing PHP"
    sudo apt install php php-{curl,cli,dev,gd,mbstring,pear,zip} -y
    echo "Configuringing PHP"
    cat << EOF > /etc/php/7.2/apache2/php.ini
file_uploads = On
allow_url_fopen = On
memory_limit = 256M
upload_max_filesize = 100M
max_execution_time = 360
date.timezone = America/Chicago
EOF
    sudo systemctl restart apache2
    echo "<?php phpinfo( ); ?>" | sudo tee /var/www/html/info.php
}
# DokuWiki Installation
dokuwiki() {
    echo "Installing DokuWiki"
    sudo apt install git -y
    cd /var/www/html/
    sudo git clone --branch stable https://github.com/splitbrain/dokuwiki.git
    echo "Changing Permissions"
    sudo chown -R www-data:www-data /var/www/html/dokuwiki/
    sudo chmod -R 755 /var/www/html/dokuwiki/
}
config() {
    echo "Configuring DokuWiki"
    echo "domain linuxadmin.dev" | sudo tee /etc/resolv.conf
    cat << STOP > /etc/apache2/sites-available/dokuwiki.conf
<VirtualHost *:80>
    ServerAdmin admin@linuxadmin.dev
    DocumentRoot /var/www/html/dokuwiki
    ServerName linuxadmin.dev
     <Directory /var/www/html/dokuwiki/>
          Options FollowSymlinks
          AllowOverride All
          Require all granted
     </Directory>
     ErrorLog ${APACHE_LOG_DIR}/error.log
     CustomLog ${APACHE_LOG_DIR}/access.log combined
     <Directory /var/www/html/dokuwiki/>
            RewriteEngine on
            RewriteBase /
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule ^(.*) index.php [PT,L]
    </Directory>
</VirtualHost>
STOP
}
# Adjusting Firewall
firewall() {
    sudo ufw allow 8080/tcp
}
restart() {
    echo "Restarting Service"
    sudo a2ensite dokuwiki.conf
    sudo a2enmod rewrite
    sudo systemctl restart apache2
    echo "Web Installation: http://linuxadmin.dev/install.php"
    exit
}
# Calling Functions
apache
php
dokuwiki
config
firewall
restart
