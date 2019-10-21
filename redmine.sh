#!/bin/bash

# Verifying Root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root, exiting."
    exit 1
fi
# Apache Installation
apache() {
    echo "Installing Apache"
    apt update
    apt install apache2 libapache2-mod-passenger -y
}
# PHP Installation
php() {
    echo "Installing PHP"
    sudo apt install libapache2-mod-php7.2 php7.2 php7.2-{cli,dev,common,gd,mbstring} -y
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
# MySQL Installation
mysql() {
    echo "Installing MySQL"
    debconf-set-selections <<< "mysql-server mysql-server/root_password password tinnitus"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password tinnitus"
    apt install mysql-server mysql-client -y
}
# Redmine Installation
redmine() {
    echo "Installing Redmine"
    apt install redmine redmine-mysql -y
    gem update && gem install bundler
}
# Redmine Configuration
conf_redmine() {
    echo "Configuring Redmine"
    rm -f /etc/apache2/mods-available/passenger.conf
    cat << STOP > /etc/apache2/mods-available/passenger.conf
<IfModule mod_passenger.c>
  PassengerDefaultUser www-data
  PassengerRoot /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini
  PassengerDefaultRuby /usr/bin/ruby
</IfModule>
STOP
    ln -s /usr/share/redmine/public /var/www/html/redmine
}
# Apache Configuration
conf_apache() {
    echo "Configuring Apache"
    rm -f /etc/apache2/sites-available/000-default.conf
    cat << STOP > /etc/apache2/mods-available/passenger.conf
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        <Directory /var/www/html/redmine>
    		RailsBaseURI /redmine
    		PassengerResolveSymlinksInDocumentRoot on
	</Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
STOP
    touch /usr/share/redmine/Gemfile.lock
    chown www-data:www-data /usr/share/redmine/Gemfile.lock
}
# Adjusting Firewall
firewall() {
    echo "Adding Exception"
    sudo ufw allow 80/tcp
    sudo ufw reload
}
# Restarting Service
service() {
    echo "Restarting Apache"
    sudo systemctl restart apache2
    sudo systemctl enable apache2
    echo "Access - http://localhost/redmine"
    exit
}
# Calling Functions
apache
php
mysql
redmine
conf_redmine
conf_apache
firewall
service
