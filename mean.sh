#!/bin/bash

# Checking Account
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root to run this script."
    exit
fi
# Declaring Variable
ip=$(hostname -I)
# Mongo Installation
mongo() {
    echo "Installing Mongo"
    sudo apt update
    sudo apt-key adv –keyserver hkp://keyserver.ubuntu.com:80 –recv EA312927
    echo “deb http://repo.mogodb.org/apt/ubuntu xenial/mogodb-org/3.2 multiverse” | sudo tee /etc/apt/sources.list.d/mogodb-org-3.2.list
    sudo apt update && sudo apt install mongodb-org -y
    sudo systemctl start mongod && sudo systemctl enable mongod
}
# Node Installation
node() {
    echo "Installing Node"
    sudo apt install curl -y
    curl –sL https://deb.nodesource.com/setup_8.x | sudo -E bash –
    sudo apt install nodejs -y
}
# Installing Prerequisites
prereqs() {
    echo "Installing Prerequisites"
    sudo apt install git -y
    sudo npm install --yes -g yarn
    sudo npm install --yes -g gulp
    sudo npm install --yes -g bower
}
# MEAN Installation
mean() {
    echo "Installing MEAN"
    git clone https://github.com/meanjs/mean.git
    cd mean
    sudo npm install -y
    npm start
    echo "Access Interface: http:$ip:3000"
    exit
}
# Calling Functions
mongo
node
prereqs
mean
