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
    sudo apt install oracle-java8-installer unzip -y
    echo JAVA_HOME=/usr/lib/jvm/java-8-oracle >> /etc/environment
    echo JRE_HOME=/usr/lib/jvm/java-8-oracle/jre >> /etc/environment
    source /etc/environment
}
# Tomcat Installation
tomcat() {
    echo "Install Tomcat"
    cd /opt/
    sudo wget --progress=bar:force https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.8/bin/apache-tomcat-9.0.8.zip
    unzip apache-tomcat-9.0.8.zip
}
# Changing Permissions
permissions() {
    chmod +x /opt/apache-tomcat-9.0.8/bin/*.sh
}
# Adding Exception
firewall() {
    echo "Adjusting Firewall"
    sudo ufw allow 8080/tcp
}
# Creating Service
create() {
    echo "Creating Service"
    cd /etc/systemd/system/
    cat << STOP > tomcat-ubuntu
    [Unit]
    Description=Tomcat 9 servlet container
    After=network.target

    [Service]
    Type=forking

    User=root
    Group=root

    Environment=JAVA_HOME=/usr/lib/jvm/java-8-oracle
    Environment=JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true

    Environment=CATALINA_BASE=/opt/apache-tomcat-9.0.8
    Environment=CATALINA_HOME=/opt/apache-tomcat-9.0.8
    Environment=CATALINA_PID=/opt/apache-tomcat-9.0.8/temp/tomcat.pid
    Environment=CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC

    ExecStart=/opt/apache-tomcat-9.0.8/bin/startup.sh
    ExecStop=/opt/apache-tomcat-9.0.8/bin/shutdown.sh

    [Install]
    WantedBy=multi-user.target
STOP
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
