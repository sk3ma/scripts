#!/bin/bash

# Checking Account
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
# Setting Variables
ip=$(hostname -I)
date=$(date +"%m-%d-%y")
# Apache Installation
apache() {
    echo "Installing Apache"
    sudo apt-get update
    sudo apt-get install apache2 apache2-utils -y
    sudo service apache2 start
    sudo systemctl enable apache2
}
# PHP Installation
php() {
    echo "Installing PHP"
    sudo apt-get install libapache2-mod-php php-{common,mbstring,mysql} -y
    echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
# Nginx Installation
nginx() {
    sudo service apache2 stop > /dev/null
    echo "Installing Nginx"
    sudo apt-get install nginx nginx-common nginx-core -y
}
config() {
    echo "Configuring Nginx"
    cp -fv /etc/nginx/nginx.conf "/etc/nginx/nginx.conf_bak-$date"
    sudo rm /var/www/html/index.html
    echo "<h1>Apache Operational</h1>" > /var/www/html/index.html
    sudo rm /etc/nginx/sites-enabled/default
    cat << END > /etc/nginx/sites-enabled/default
server {
	listen 80 default_server;
	root /var/www/html;
	index.html index.nginx-debian.html
	server_name_;
	location / {
		try_files $uri $uri/ =404;
		proxy_pass http://localhost:8080;
	}
}
END
    sudo service nginx restart
}
# Nginx Configuration
port() {
    echo "Configuring Ports"
    sudo rm /etc/apache2/ports.conf
    cat << END > /etc/apache2/ports.conf
Listen 8080
<ifModule ssl_module>
	Listen 443
</ifModule>
<ifModule mod_gnutls.c>
	Listen 443
</ifModule>
END
}
restart() {
    sudo service apache2 start
    sudo systemctl enable nginx
    echo "Access: http://$ip"
    exit
}
# Calling Functions
apache
php
nginx
config
port
restart
