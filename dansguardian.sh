#!/bin/bash

# Checking Account
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root to run this script."
    exit
fi
# Webserver Installation
web() {
    echo "Installing Apache"
    sudo apt update
    sudo apt install apache2 apache2-utils -y
    echo "Installing PHP"
    sudo apt install libapache2-mod-php php-{cli,dev,common,gd,mbstring} -y
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
}
# Webfilter Installation
squid() {
    echo "Installing Squid"
    sudo apt install squid squid-common -y
    echo "Installing Dansguardian"
    sudo apt install dansguardian clamav clamav-freshclam -y
    sudo systemctl enable squid
    sudo systemctl enable dansguardian
}
# Dansguardian Configuration
config() {
    echo "Configuring Dansguardian"
    cp -fv /etc/dansguardian/dansguardian.conf "/etc/dansguardian/dansguardian.conf_bak-$(date +"%m-%d-%y")"
    rm /etc/dansguardian/dansguardian.conf
    cat << STOP > /etc/dansguardian/dansguardian.conf
reportinglevel = 3
languagedir = '/etc/dansguardian1/languages'
language = 'english'
loglevel = 1
logexceptionhits = 0
logfileformat = 1
loglocation = '/var/log/dansguardian2/access.log'
filterip =
filterport = 8080
proxyip = 127.0.0.1
proxyport = 3128
accessdeniedaddress = 'http://YOURSERVER.YOURDOMAIN/cgi-bin/dansguardian.pl'
nonstandarddelimiter = on
usecustombannedimage = on
custombannedimagefile = '/usr/share/dansguardian/transparent1x1.gif'

filtergroups = 1
filtergroupslist = '/etc/dansguardian2/lists/filtergroupslist'
bannediplist = '/etc/dansguardian2/lists/bannediplist'
bannedsitelist = '/etc/dansguardian/lists/bannedsitelist'
exceptioniplist = '/etc/dansguardian2/lists/exceptioniplist'

showweightedfound = on
weightedphrasemode = 2
urlcachenumber = 1000
urlcacheage = 900
scancleancache = on
phrasefiltermode = 2
preservecase = 0
hexdecodecontent = off
forcequicksearch = off
reverseaddresslookups = off
reverseclientiplookups = off
logclienthostnames = off
createlistcachefiles = on
maxuploadsize = -1
maxcontentfiltersize = 256
maxcontentramcachescansize = 2000
maxcontentfilecachescansize = 20000
filecachedir = '/tmp'
deletedownloadedtempfiles = on
initialtrickledelay = 20
trickledelay = 10

downloadmanager = '/etc/dansguardian2/downloadmanagers/fancy.conf'
downloadmanager = '/etc/dansguardian2/downloadmanagers/default.conf'

contentscannertimeout = 60
contentscanexceptions = off
recheckreplacedurls = off
forwardedfor = off
usexforwardedfor = off
logconnectionhandlingerrors = on
logchildprocesshandling = off

maxchildren = 120
minchildren = 8
minsparechildren = 4
preforkchildren = 6
maxsparechildren = 32
maxagechildren = 500
maxips = 0

ipcfilename = '/tmp/.dguardian2ipc'
urlipcfilename = '/tmp/.dguardian2urlipc'
ipipcfilename = '/tmp/.dguardian2ipipc'
pidfilename = '/var/run/dansguardian2.pid'

nodaemon = off
nologger = off
logadblocks = off
loguseragent = off
softrestart = off

mailer = '/usr/sbin/sendmail -t'
STOP
}
# Blocking File
block() {
    cat << STOP > /etc/dansguardian/lists/bannedsitelist
www.facebook.com
www.youtube.com
STOP
}
# Addng Exception
firewall() {
    echo "Adjusting Firewall"
    firewall-cmd --add-port=3128/tcp --permanent
    firewall-cmd --add-port=8080/tcp --permanent
    firewall-cmd --reload
}
# Applying Changes
service() {
    echo "Restarting Services"
    systemctl restart squid
    systemctl restart dansguardian
    echo "Update web browser proxy settings"
    exit
}
# Calling Functions
web
squid
config
block
firewall
service
