#!/bin/bash

# Verifying Root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root, exiting."
    exit 1
fi
# Installing Components
webserver() {
    echo "Installing Apache"
    sudo apt-get update
    sudo apt-get install apache2 zip unzip -y
    echo "Installing PHP"
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt-get update
    sudo apt-get install libapache2-mod-php7.2 php7.2 php7.2-{gd,common,xml,opcache,mbstring} -y
    echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
}
# Installing Database
database() {
    echo "Installing MySQL"
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password letmein"
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password letmein"
    sudo apt-get install mysql-server -y
}
# Laravel Installation
laravel() {
    echo "Installing Laravel"
    cd /tmp
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
}
# Creating Laravel
application() {
    echo "Configuring Laravel"
    cd /var/www/html
    sudo composer create-project laravel/laravel myProject --prefer-dist
}
# Configuring Apache
permissions() {
    echo "Changing Permissions"
    sudo chgrp -R www-data /var/www/html/myProject
    sudo chmod -R 775 /var/www/html/myProject/storage
}
# Creating Virtualhost
vhost() {
    sudo cat << STOP > /etc/apache2/sites-available/laravel.conf
<VirtualHost *:80>
    ServerName localhost
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/myProject/public
    <Directory /var/www/html/myProject>
        AllowOverride All
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
STOP
}
# Enabling Virtualhost
config() {
    echo "Enabling Configuration"
    sudo a2dissite 000-default.conf
    sudo a2ensite laravel.conf
    sudo a2enmod rewrite
}
# Adding Exception
firewall() {
    echo "Adjusting Firewall"
    sudo ufw allow 80/tcp
    sudo ufw reload
}
# Restarting Apache
restart() {
    echo "Restarting Service"
    sudo systemctl restart apache2
    exit
}
# Calling Functions
webserver
database
laravel
permissions
vhost
config
firewall
restart
