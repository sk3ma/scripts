#!/bin/bash

# Checking Account
if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo -e "You must be root to run this script."
  exit
fi
# Squid Installation
install() {
    echo "Installing Squid"
    yum install epel-release -y
    yum install squid -y
}
# Starting Service
service() {
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
# Squid Configuration
config() {
    echo "Configuring Squid "
    cat << STOP > /etc/squid/squid.conf
acl lan src 192.168.33.0/24
acl password proxy_auth REQUIRED
http_access allow lan
acl blacklist urlpath_regex "/etc/squid/blacklist"
STOP
}
# Blacklist File
block() {
    echo "Creating File"
    touch /etc/squid/blacklist
    echo 'www.facebook.com' > /etc/squid/blacklist
    echo 'www.youtube.com' >> /etc/squid/blacklist
}
# Restarting Service
restart() {
    echo "Restarting Squid"
    systemctl restart squid
    exit
# Calling Functions
install
service
backup
config
block
restart
