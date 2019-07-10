#!/bin/bash

# Checking Account
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root to run this script."
    exit
fi
# Settings Variables
domain=$1
username=$(echo $domain | cut -d. -f1)
ipaddr=$(hostname -I)
# Checking Domain
domain() {
    if [[ $domain == '' ]]; then
        echo -e "Usage: ./install_nginx domain-name.tld"
        exit
    elif [[ $(grep -o "\." <<< "$domain" | wc -l) > 1 || $(grep -o "\." <<< "$domain" | wc -l) < 1 ]]; then
        echo -e "Invalid domain! Usage: ./install_nginx domain-name.tld"
        exit
    fi
}
# Installing Nginx
install() {
    yum update -y
    echo -e "[nginx]\nname=nginx repo\nbaseurl=http://nginx.org/packages/rhel/7/\$basearch/\ngpgcheck=0\nenabled=1" >> /etc/yum.repos.d/nginx.repo
    yum install nginx -y
    echo "Starting Nginx"
    systemctl start nginx && systemctl enable nginx
    echo "Adjusting Firewall"
    firewall-cmd --zone=public --add-service=http --permanent
    firewall-cmd --zone=public --add-service=https --permanent
    firewall-cmd --reload
    echo "Restarting Nginx"
    systemctl restart nginx
}
# Settings User
user() {
    echo "Defining User"
    useradd -s /sbin/nologin $username
    chmod go+x /home/$username
    mkdir /home/$username/logs
    mkdir /home/$username/public_html
    chcon -Rvt httpd_log_t /home/$username/logs/
    chcon -Rvt httpd_sys_content_t /home/$username/public_html/
    echo -e "<html>\n<head>\n\t<title>NGINX - TEST</title>\n</head>\n<body>\n\t<h3>THIS IS A TEST<h3>\n\t<h4>Index file loaded from /home/$username/public_html/<h4>\n</body>\n</html>" >> /home/$username/public_html/index.html
    chown -Rv $username:$username /home/$username
}
# Virtual Host
host() {
    echo "Configuration Backup"
    cp -fv /etc/nginx/nginx.conf "/etc/nginx/nginx.conf_bak-$(date +"%m-%d-%y")"
    mkdir /etc/nginx/sites-available
    mkdir /etc/nginx/sites-enabled
    echo "Setting Configuration"
    awk '
    { print }
    /etc\/nginx\/conf.d\/\*/ {
    print "    include /etc/nginx/sites-enabled/*.conf;"
    }
    ' /etc/nginx/nginx.tmp.conf > /etc/nginx/nginx.tmp.conf && mv /etc/nginx/nginx.tmp.conf /etc/nginx/nginx.conf
    cat > /etc/nginx/sites-available/$username.com.conf <<nginx
server {
    listen  80;
    server_name $username.com www.$username.com;
    access_log /home/$username/logs/access.log;
    error_log /home/$username/logs/error.log;
    location / {
        root  /home/$username/public_html;
        index  index.html index.htm index.php;
        try_files \$uri \$uri/ =404;
    }
    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
        root  /usr/share/nginx/html;
    }
}
nginx
    echo "Enabling Configuration"
    ln -sv /etc/nginx/sites-available/$username.com.conf /etc/nginx/sites-enabled/$username.com.conf
    nginx -t
    echo "Restarting Nginx"
    systemctl restart nginx
    echo -e "\n\nAdd entries to the hosts file\n\n$ipaddr\t$domain www.$domain\n\n"
    exit
}
# Calling Functions
domain
install
user
host
