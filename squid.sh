#!/bin/bash

# Checking Account
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root to run this script."
    exit
fi
# Installing Squid
install() {
    echo "Installing Squid"
    yum update -y
    yum install epel-release -y
    yum install squid -y
}
# Starting Service
start() {
    echo "Adjusting Firewall"
    firewall-cmd --add-service=squid --permanent
    firewall-cmd --reload
    echo "Starting Squid"
    systemctl start squid
    systemctl enable squid
}
# Backup Configuration
backup() {
    echo "Configuration Backup"
    cp -fv /etc/squid/squid.conf "/etc/squid/squid.conf_bak-$(date +"%m-%d-%y")"
}
# Blocked File
config() {
    echo "Creating File"
    touch /etc/squid/blocked_sites
    echo 'www.facebook.com' > /etc/squid/blocked_sites
    echo 'www.youtube.com' >> /etc/squid/blocked_sites
}
# Restarting Service
restart() {
    echo "Restarting Squid"
    systemctl restart squid
    exit
# Calling Functions
install
start
backup
config
restart
