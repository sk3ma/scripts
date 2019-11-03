#!/bin/bash

# Verifying Root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root, exiting."
    exit 1
fi
# Setting Variables
ip=$(hostname -I)
date=$(date +"%m-%d-%y")
# Apache Installation
apache() {
    echo "Installing Apache"
    sudo apt update
    sudo apt install apache2 apache2-utils -y
    sudo service apache2 start
    sudo systemctl enable apache2
}
# PHP Installation
php() {
    echo "Installing PHP"
    sudo apt install libapache2-mod-php php-{cli,dev,common,gd,mbstring} -y
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
}
# Nginx Installation
nginx() {
    sudo service apache2 stop > /dev/null
    echo "Installing Nginx"
    sudo apt install nginx nginx-{common,core} -y
}
config() {
    echo "Configuring Nginx"
    cp -fv /etc/nginx/nginx.conf "/etc/nginx/nginx.conf_bak-$date"
    sudo rm /var/www/html/index.html
    echo "<h1>Apache Operational</h1>" > /var/www/html/index.html
    sudo rm /etc/nginx/sites-enabled/default
    cat << STOP > /etc/nginx/sites-enabled/default
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
STOP
    sudo service nginx restart
}
# Nginx Configuration
port() {
    echo "Configuring Ports"
    sudo rm /etc/apache2/ports.conf
    sed -i -e 's/80/8080/g' /etc/apache2/ports.conf
}
# Adjusting Firewall
firewall() {
    sudo ufw allow 8080/tcp
    sudo ufw reload
}
restart() {
    echo "Restarting Service"
    sudo service apache2 start
    sudo systemctl enable nginx
    exit
}
# Calling Functions
apache
php
nginx
config
port
firewall
restart
