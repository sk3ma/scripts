#!/bin/bash

# Checking Account
if [[ $(/usr/bin/id -u) != "0" ]]; then
  echo -e "You must be root to run this script."
  exit
fi
# Java Installation
java() {
    echo "Installing Java"
    yum update -y
    yum install java -y
    version=$(java -version 2>&1 >/dev/null | grep 'version')
    echo -e "\n\nJava Version: $version\n\n"
}
# Jenkins Installation
jenkins() {
    echo "Installing Jenkins"
    wget -q -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    yum install jenkins -y
    echo "Starting Jenkins"
    systemctl start jenkins
    systemctl enable jenkins
}
# Adjusting Firewall
firewall() {
    echo "Adjusting Firewall"
    systemctl start firewalld
    firewall-cmd --zone=public --add-port=8080/tcp --permanent
    firewall-cmd --reload
    echo "Access Jenkins: http://localhost:8080"
    exit
}
# Calling Functions
java
jenkins
firewall
