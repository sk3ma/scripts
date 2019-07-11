#!/bin/bash

# Checking Account
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
# IP Address
ip=$(hostname -I)
# Apache Installation
apache() {
    echo "Installing Apache"
    sudo apt-get update
    sudo apt-get install apache2 apache2-utils -y
    sudo service apache2 start
    sudo systemctl enable apache2
}
# Nginx Installation
nginx () {
    sudo service apache2 stop
    echo "Installing Nginx"
    sudo apt-get install nginx nginx-common nginx-core -y
    sudo rm /var/www/html/index.html
    sudo rm /etc/nginx/sites-enabled/default
    cat << END >> /etc/nginx/sites-enabled/default
server {
	listen 80 default_server;
	root /var/www/html;
	index.nginx-debian.html
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
    echo "Configuring Nginx"
    sudo rm /etc/apache2/ports.conf
    cat << END >> /etc/apache2/ports.conf
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
    sudo service apache2 restart
    sudo systemctl enable nginx
    echo "Apache Access: http://$ip"
    exit
}
# Calling Functions
apache
nginx
port
restart
