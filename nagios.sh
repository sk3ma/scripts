#!/bin/bash

# Verifying Root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root, exiting."
    exit 1
fi
# Setting Variables
ip=$(hostname -I)
NAGIOS_VERSION="4.0.8"
NAGIOS_PLUGINGS="2.0.3"
NAGIOS_HOME="/usr/local/nagios"
# Webserver Installation
webserver() {
    echo "Installing Apache"
    sudo apt update
    sudo apt install apache2 apache2-utils build-essential libgd2-xpm-dev openssl libssl-dev -y
    echo "Installing PHP"
    sudo apt install libapache2-mod-php php-{cli,dev,common,gd,mbstring} -y
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
}
# Changing ownership
permissions() {
    echo "Changing permissions"
    sudo useradd nagios && sudo groupadd nagcmd
    sudo usermod -aG nagcmd nagios && sudo usermod -aG nagcmd apache
}
# Nagios Retrieval
nagios() {
    echo "Downloading Nagios"
    sudo mkdir -p /tmp/download
    sudo wget --progress=bar:force https://assets.nagios.com/downloads/nagioscore/releases/nagios-$NAGIOS_VERSION.tar.gz
}
# Nagios Installation
install() {
    echo "Downloading Nagios Core"
    tar xvzf nagios-$NAGIOS_VERSION.tar.gz
    cd nagios-$NAGIOS_VERSION
    sudo ./configure --with-nagios-group=nagios --with-command-group=nagcmd
    sudo make all
    sudo make install
    sudo make install-init
    sudo make install-commandmode
    sudo make install-config
    sudo /usr/bin/install -c -m 644 sample-config/httpd.conf /etc/apache2/sites-available/nagios.conf
}
# Plugins Retrieval
plugins() {
    echo "Downloading Nagios Plugins"
    sudo wget --progress=bar:force https://nagios-plugins.org/download/nagios-plugins-$NAGIOS_PLUGINGS.tar.gz
    tar xzf /tmp/download/nagios-plugins-$NAGIOS_PLUGINGS.tar.gz -C /tmp/download
    cd /tmp/download/nagios-plugins-$NAGIOS_PLUGINGS
    ./configure --with-nagios-user=nagios --with-nagios-group=nagcmd --with-openssl
    sudo make
    sudo make install
    sudo chown nagios.nagios /usr/local/nagios
    sudo chown -R nagios:nagios /usr/local/nagios/libexec
}
# Nagios Configuration
config() {
    echo "Configuring Nagios"
    sudo mkdir -p /usr/local/nagios/etc/servers
    sudo echo 'cfg_dir=/usr/local/nagios/etc/servers' >>/usr/local/nagios/etc/nagios.cfg
    cat << STOP > usr/local/nagios/etc/objects/contacts.cfg
contact_name                    nagiosadmin
use                             generic-contact
alias                           Nagios Admin
email                           nagios@localhost
STOP
    /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
}
# Enabling Modules
modules() {
    echo "Enabling Modules"
    sudo a2enmod rewrite
    sudo a2enmod cgi
}
# Setting Credentials
credentials() {
    echo "Setting Credentials"
    sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
}
# Adding Exception
firewall() {
    echo "Adjusting Firewall"
    sudo ufw allow 8080/tcp
    sudo ufw reload
}
# Enabling Configuration
enable() {
    echo "Enabling Nagios"
    sudo ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/
    sudo ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios
    echo "Web Access: http://$ip/nagios"
    exit
}
# Calling Functions
webserver
permissions
nagios
install
plugins
config
modules
credentials
enable
