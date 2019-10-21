#!/bin/bash

# Verifying Root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root, exiting."
    exit 1
fi
# Apache Installation
apache() {
    echo "Installing Apache"
    apt update -y
    sudo apt install apache2 apache2-utils -y
    sudo systemctl start apache2 && sudo systemctl enable apache2
}
# PHP Installation
php() {
    echo "Installing PHP"
    sudo apt install php7.2 libapache2-mod-php7.2 php7.2-{cli,dev,common,gd,mbstring} -y
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
}
# MySQL Installation
mysql() {
    echo "Installing MySQL"
    debconf-set-selections <<< "mysql-server mysql-server/root_password password tinnitus"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password tinnitus"
    apt install mysql-server mysql-client php-mysql -y
}
# Retrieving Wordpress
wordpress() {
    echo "Creating Database"
    rm /var/www/html/index.*
    wget progress=bar:force http://wordpress.org/latest.tar.gz && tar -xzvf latest.tar.gz
    rsync -av wordpress/* /var/www/html
}
# Changing Permissions
permissions() {
    echo "Changing Permissions"
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
}
# Database Creation
database() {
    echo "Creating Database"
    mysql -uroot -ptinnitus << STOP
CREATE DATABASE testdb;
GRANT ALL PRIVILEGES ON testdb.* TO 'root'@'localhost' IDENTIFIED BY 'tinnitus';
FLUSH PRIVILEGES;
EXIT
STOP
}
# Wordpress Configuration
configuration() {
    echo "Configuring Wordpress"
    cd /var/www/html
    sudo mv wp-config-sample.php wp-config.php
    perl -pi -e "s/database_name_here/$wordpress_db_name/g" wp-config.php
    perl -pi -e "s/username_here/root/g" wp-config.php
    perl -pi -e "s/password_here/$db_root_password/g" wp-config.php
}
# Creating Exception
firewall() {
    echo "Adjusting Firewall"
    sudo ufw allow 80/tcp
    sudo ufw reload
}
# Restarting Services
restart() {
    echo "Restarting Services"
    a2enmod rewrite
    sudo systemctl restart apache2
    sudo systemctl restart mysql
    exit
}
# Calling Functions
apache
php
mysql
wordpress
permissions
database
configuration
firewall
restart
