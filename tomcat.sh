#!/bin/bash

# Checking Account
if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo -e "You must be root to run this script."
  exit
fi
# Java Installation
java() {
    echo "Installing Java"
    sudo add-apt-repository ppa:webupd8team/java -y
    sudo apt update
    echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
    sudo apt install oracle-java8-installer -y
    echo JAVA_HOME=/usr/lib/jvm/java-8-oracle >> /etc/environment
    echo JRE_HOME=/usr/lib/jvm/java-8-oracle/jre >> /etc/environment
    source /etc/environment
}
# Tomcat Installation
tomcat() {
    echo "Install Tomcat"
    sudo apt install unzip -y
    cd /opt/
    sudo wget --progress=bar:force https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.8/bin/apache-tomcat-9.0.8.zip
    unzip apache-tomcat-9.0.8.zip
}
# Setting Permissions
permissions() {
    chmod +x /opt/apache-tomcat-9.0.8/bin/*.sh
}
# Adding Exception
firewall() {
    echo "Adjusting Firewall"
    ufw allow 8080/tcp
}
# Creating Service
create() {
    echo "Creating Service"
    cd /etc/systemd/system/
    sudo wget --progress=bar:force https://s3.amazonaws.com/serverkaka-pubic-file/tomcat-ubuntu
    mv tomcat-ubuntu tomcat.service
}
# Starting Tomcat
start() {
    echo "Starting Service"
    sudo systemctl daemon-reload
    sudo systemctl start tomcat
    sudo systemctl enable tomcat
    echo "Tomcat Access: http://localhost:8080"
    exit
}
# Executing Functions
java
tomcat
permissions
firewall
create
start
