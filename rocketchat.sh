#!/bin/bash

# Verifying Root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root, exiting."
    exit 1
fi
# Setting Variables
ip=$(hostname -I)
# Package Dependencies
package() {
    echo "Checking Dependencies"
    sudo yum upgrade -y
    sudo yum check-update -y
}
# MongoDB Installation
mongo() {
    echo "Installing MongoDB"
    cat << STOP > /etc/yum.repos.d/mongodb-org-4.0.repo
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
STOP
}
# Node Installation
node() {
    echo "Installing Node.js"
    sudo yum install epel-release -y
    sudo yum install curl -y
    curl -sL https://rpm.nodesource.com/setup_8.x | sudo bash -
    sudo yum install gcc-c++ make mongodb-org nodejs -y
    sudo yum install GraphicsMagick -y
    sudo npm install -g inherits n && sudo n 8.11.4
}
# Rocketchat Installation
rocket() {
    echo "Installing Rocketchat"
    curl -L https://releases.rocket.chat/latest/download -o /tmp/rocket.chat.tgz
    tar -xzf /tmp/rocket.chat.tgz -C /tmp
}
# Rocketchat Configuration
rocket_config() {
    echo "Configuring Rocketchat"
    cd /tmp/bundle/programs/server
    sudo npm install
    sudo mv /tmp/bundle /opt/Rocket.Chat
}
# User Creation
user() {
    echo "Creating User"
    sudo useradd -M rocketchat
    sudo usermod -L rocketchat
    sudo chown -R rocketchat:rocketchat /opt/Rocket.Chat
}
# Service Creation
service() {
    echo "Creating Service"
    cat << STOP > /lib/systemd/system/rocketchat.service
[Unit]
Description=The Rocket.Chat server
After=network.target remote-fs.target nss-lookup.target nginx.target mongod.target
[Service]
ExecStart=/usr/local/bin/node /opt/Rocket.Chat/main.js
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rocketchat
User=rocketchat
Environment=MONGO_URL=mongodb://localhost:27017/rocketchat?replicaSet=rs01 MONGO_OPLOG_URL=mongodb://localhost:27017/local?replicaSet=rs01 ROOT_URL=http://localhost:3000/ PORT=3000
[Install]
WantedBy=multi-user.target
STOP
}
# MongoDB Configuration
mongo_config() {
    echo "Configuring MongoDB"
    sudo sed -i "s/^#  engine:/  engine: mmapv1/" /etc/mongod.conf
    sudo sed -i "s/^#replication:/replication:\n  replSetName: rs01/" /etc/mongod.conf
}
# Starting Services
start() {
    echo "Starting MongoDB"
    sudo systemctl enable mongod
    sudo systemctl start mongod
    echo "Starting Rocketchat"
    sudo systemctl enable rocketchat
    sudo systemctl start rocketchat
    echo "Web Access: http://$ip:3000"
    exit
}
# Executing Functions
package
mongo
node
rocket
rocket_config
user
service
mongo_config
start
