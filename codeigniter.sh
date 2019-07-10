#!/bin/bash

# Checking Account
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root to run this script."
    exit
fi
# Apache Installation
apache() {
    echo "Installing Apache"
    sudo apt update
    sudo apt-get install apache2 -y
    sudo apt-get install python-software-properties -y
    echo "Installing PHP"
}
# PHP Installation
php() {
    echo "Installing PHP"
    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt-get install libapache2-mod-php7.1 php7.1-common php7.1-xml php7.1-zip php7.1-mysql unzip wget -y
    echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
}
service() {
    echo "Starting Apache"
    sudo systemctl start apache2
    sudo systemctl enable apache2
}
# MySQL Installion
mysql() {
    echo "Installing MySQL"
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password logmein'
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password logmein'
    sudo apt install mysql-server php7.2-mysql -y
    echo "Starting MySQL"
    sudo systemctl start mysql
}
# Fetching CodeIgniter
code() {
    echo "Downloading CodeIgniter"
    wget --progress=bar:force https://github.com/bcit-ci/CodeIgniter/archive/3.1.5.zip
    unzip 3.1.5.zip
    sudo mv CodeIgniter-3.1.5 codeigniter
}
# Creating Database
database() {
    echo "Creating Database"
    mysql -u root -plogmein < /vagrant/db.sql
}
# CodeIgniter Database
config() {
    echo "Adding Configuration"
    sudo cat << END > /var/www/html/codeigniter/application/config/database.php
$db['default'] = array(
'dsn' => '',
'hostname' => 'localhost',
'username' => 'osadmin',
'password' => 'logmein',
'database' => 'codeigniter',
'dbdriver' => 'mysqli',
'dbprefix' => '',
'pconnect' => FALSE,
'db_debug' => (ENVIRONMENT !== 'production'),
'cache_on' => FALSE,
'cachedir' => '',
'char_set' => 'utf8',
'dbcollat' => 'utf8_general_ci',
'swap_pre' => '',
'encrypt' => FALSE,
'compress' => FALSE,
'stricton' => FALSE,
'failover' => array(),
'save_queries' => TRUE
);
END
}
# CodeIgniter Host
host() {
    echo "Adding Configuration"
    sudo cat << END > /etc/apache2/sites-available/codeigniter.conf
<VirtualHost *:80>
ServerAdmin admin@example.com
DocumentRoot /var/www/html/codeigniter
ServerName example.com
<Directory /var/www/html/codeigniter/>
Options +FollowSymLinks
AllowOverride All
Order allow,deny
allow from all
</Directory>
ErrorLog /var/log/apache2/codeigniter-error_log
CustomLog /var/log/apache2/codeigniter-access_log common
</VirtualHost>
END
}
# Changing Ownership
owner() {
    sudo cp -r codeigniter /var/www/html/codeigniter
    sudo chown -R www-data:www-data /var/www/html/codeigniter
    sudo chmod -R 777 /var/www/html/codeigniter/
}
# Adjusting Firewall
firewall() {
    echo "Allowing CodeIgniter"
    sudo ufw allow 8080/tcp
    sudo a2ensite codeigniter
}
# Restarting Apache
restart() {
    echo "Restarting Apache"
    systemctl restart apache2
    echo "CodeIgniter Access: 192.168.33.45/codeigniter"
    exit
}
# Executing Functions
apache
php
service
mysql
code
database
config
host
owner
firewall
restart
