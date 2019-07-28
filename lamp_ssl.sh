#!/bin/bash

# Checking Account
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root to run this script."
    exit
fi
# Setting Varaible
ip=$(hostname -I)
passphrase=changemenow
# Installing Apache
apache() {
    echo  "Installing Apache"
    sudo apt update
    sudo apt install apache2 apache2-utils openssl -y
    echo "<h1>Apache Operational</h1>" > /var/www/html/index.html
}
php() {
    echo "Installing PHP"
    sudo apt-get install libapache2-mod-php7.2 php7.2 php7.2-{gd,common,xml,opcache,mbstring} -y
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
}
# Configuring Apache
config() {
    echo "letmein" | sudo htpasswd -c -i /var/www/html/.htpasswd webuser
    cat << STOP > .htaccess
AuthName "Authentication Required"
AuthType Basic
AuthUserFile /var/www/html/.htpasswd
AuthGroupFile /dev/null
require valid-user
STOP
    mkdir -p /etc/apache2/ssl
    sudo openssl req -new -x509 -days 365 -nodes -out /etc/apache2/ssl/mycert.crt -keyout /etc/apache2/ssl/mykey.key -passin pass:$passphrase
    chmod -R 600 /etc/apache2/ssl/mykey.key
}
# Installing MySQL
mysql() {
    echo "Installing MySQL"
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password logmein'
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password logmein'
    sudo apt install mysql-server php7.2-mysql -y
    echo "Starting Service"
    sudo systemctl start mysql
# User Creation
user() {
    echo "Creating User"
    cat << STOP > /var/www/html/user.sql
CREATE DATABASE myDatabase;
CREATE USER 'myUser'@'localhost' IDENTIFIED BY 'myPasswd';
GRANT ALL PRIVILEGES ON myDatabase.* TO 'myUser'@'localhost';
FLUSH PRIVILEGES;
STOP
    mysql -u root -plogmein < /var/www/html/user.sql
}
# Creating Exception
firewall() {
    echo "Adjusting Firewall"
    sudo ufw allow 80/tcp
}
# Restarting Service
restart() {
    echo "Restarting Apache"
    sudo systemctl restart apache2
    echo "Web Access: http://$ip"
    exit
}
# Calling Functions
apache
php
config
mysql
user
firewall
restart
