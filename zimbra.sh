#!/bin/bash

# Verifying Root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "You must be root, exiting."
    exit 1
fi
# Variable Preparation
RANDOMHAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMSPAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMVIRUS=$(date +%s|sha256sum|base64|head -c 10)
HOSTNAME=$(hostname -s)
# Installing BIND
bind() {
    sudo apt update
    sudo apt install bind9 bind9utils -y
    echo "Installing BIND"
    sed "s/-u/-4 -u/g" /etc/default/bind9 > /etc/default/bind9.new
    mv /etc/default/bind9.new /etc/default/bind9
    rm /etc/bind/named.conf.options
}
# BIND Configuration
bind_config() {
    cat << STOP > /etc/bind/named.conf.options
options {
directory "/var/cache/bind";
listen-on { $2; }; # ns1 private IP address - listen on private network only
allow-transfer { none; }; # disable zone transfers by default
forwarders {
8.8.8.8;
8.8.4.4;
};
auth-nxdomain no;
#listen-on-v6 { any; };
};
STOP
    cat << STOP > /etc/bind/named.conf.local
zone "$1" {
        type master;
        file "/etc/bind/db.$1";
};
STOP
    touch /etc/bind/db.$1
    cat << STOP > /etc/bind/db.$1
\$TTL  604800
@      IN      SOA    ns1.$1. root.localhost. (
                                2        ; Serial
                        604800        ; Refresh
                        86400        ; Retry
                        2419200        ; Expire
                        604800 )      ; Negative Cache TTL
    ;
    @     IN      NS      ns1.$1.
    @     IN      A      $2
    @     IN      MX     10     $HOSTNAME.$1.
    $HOSTNAME     IN      A      $2
    ns1     IN      A      $2
    mail     IN      A      $2
    pop3     IN      A      $2
    imap     IN      A      $2
    imap4     IN      A      $2
    smtp     IN      A      $2
STOP
    sudo service bind9 restart
}
# Zimbra Configuration
zimbra_config() {
    echo "Applying Configuration"
    mkdir /tmp/zcs && cd !*
    touch /tmp/zcs/installZimbraScript
    cat << END >/tmp/zcs/installZimbraScript
AVDOMAIN="$1"
AVUSER="admin@$1"
CREATEADMIN="admin@$1"
CREATEADMINPASS="$3"
CREATEDOMAIN="$1"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
DOTRAINSA="yes"
EXPANDMENU="no"
HOSTNAME="$HOSTNAME.$1"
HTTPPORT="8080"
HTTPPROXY="TRUE"
HTTPPROXYPORT="80"
HTTPSPORT="8443"
HTTPSPROXYPORT="443"
IMAPPORT="7143"
IMAPPROXYPORT="143"
IMAPSSLPORT="7993"
IMAPSSLPROXYPORT="993"
INSTALL_WEBAPPS="service zimlet zimbra zimbraAdmin"
JAVAHOME="/opt/zimbra/common/lib/jvm/java"
LDAPAMAVISPASS="$3"
LDAPPOSTPASS="$3"
LDAPROOTPASS="$3"
LDAPADMINPASS="$3"
LDAPREPPASS="$3"
LDAPBESSEARCHSET="set"
LDAPDEFAULTSLOADED="1"
LDAPHOST="$HOSTNAME.$1"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="2"
MAILBOXDMEMORY="512"
MAILPROXY="TRUE"
MODE="https"
MYSQLMEMORYPERCENT="30"
POPPORT="7110"
POPPROXYPORT="110"
POPSSLPORT="7995"
POPSSLPROXYPORT="995"
PROXYMODE="https"
REMOVE="no"
RUNARCHIVING="no"
RUNAV="yes"
RUNCBPOLICYD="no"
RUNDKIM="yes"
RUNSA="yes"
RUNVMHA="no"
SERVICEWEBAPP="yes"
SMTPDEST="admin@$1"
SMTPHOST="$HOSTNAME.$1"
SMTPNOTIFY="yes"
SMTPSOURCE="admin@$1"
SNMPNOTIFY="yes"
SNMPTRAPHOST="$HOSTNAME.$1"
SPELLURL="http://$HOSTNAME.$1:7780/aspell.php"
STARTSERVERS="yes"
SYSTEMMEMORY="3.8"
TRAINSAHAM="ham.$RANDOMHAM@$1"
TRAINSASPAM="spam.$RANDOMSPAM@$1"
UIWEBAPPS="yes"
UPGRADE="yes"
USEKBSHORTCUTS="TRUE"
USESPELL="yes"
VERSIONUPDATECHECKS="TRUE"
VIRUSQUARANTINE="virus-quarantine.$RANDOMVIRUS@$1"
ZIMBRA_REQ_SECURITY="yes"
ldap_bes_searcher_password="$3"
ldap_dit_base_dn_config="cn=zimbra"
ldap_nginx_password="$3"
ldap_url="ldap://$HOSTNAME.$1:389"
mailboxd_directory="/opt/zimbra/mailboxd"
mailboxd_keystore="/opt/zimbra/mailboxd/etc/keystore"
mailboxd_keystore_password="$3"
mailboxd_server="jetty"
mailboxd_truststore="/opt/zimbra/common/lib/jvm/java/jre/lib/security/cacerts"
mailboxd_truststore_password="changeit"
postfix_mail_owner="postfix"
postfix_setgid_group="postdrop"
ssl_default_digest="sha256"
zimbraDNSMasterIP=""
zimbraDNSTCPUpstream="no"
zimbraDNSUseTCP="yes"
zimbraDNSUseUDP="yes"
zimbraDefaultDomainName="$1"
zimbraFeatureBriefcasesEnabled="Enabled"
zimbraFeatureTasksEnabled="Enabled"
zimbraIPMode="ipv4"
zimbraMailProxy="FALSE"
zimbraMtaMyNetworks="127.0.0.0/8 $2/32 [::1]/128 [fe80::]/64"
zimbraPrefTimeZoneId="America/Los_Angeles"
zimbraReverseProxyLookupTarget="TRUE"
zimbraVersionCheckInterval="1d"
zimbraVersionCheckNotificationEmail="admin@$1"
zimbraVersionCheckNotificationEmailFrom="admin@$1"
zimbraVersionCheckSendNotifications="TRUE"
zimbraWebProxy="FALSE"
zimbra_ldap_userdn="uid=zimbra,cn=admins,cn=zimbra"
zimbra_require_interprocess_security="1"
zimbra_server_hostname="$HOSTNAME.$1"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-snmp zimbra-store zimbra-apache zimbra-spell zimbra-memcached zimbra-proxy"
END
}
# Answering Automatically
answer() {
    touch /tmp/zcs/installZimbra-keystrokes
    cat << STOP > /tmp/zcs/installZimbra-keystrokes
y
y
y
y
y
n
y
y
y
y
y
y
y
n
y
y
STOP
}
# Installing Zimbra
zimbra() {
    echo "Downloading Zimbra"
    wget --progress=bar:force https://files.zimbra.com/downloads/8.8.10_GA/zcs-8.8.10_GA_3039.UBUNTU16_64.20180928094617.tgz
    tar xzvf zcs-*
    echo "Installing Zimbra"
    cd /tmp/zcs/zcs-*
    ./install.sh -s < /tmp/zcs/installZimbra-keystrokes
    /opt/zimbra/libexec/zmsetup.pl -c /tmp/zcs/installZimbraScript
}
# Restarting Zimbra
restart() {
    echo "Restarting Zimbra"
    su - zimbra -c 'zmcontrol restart'
}
# Enabling Zimbra
enable() {
    echo "Enabling Zimbra"
    cat <(crontab -l) <(echo "@reboot su - zimbra -c 'zmcontrol start'") | crontab -
    echo "Admin Console: https://"$2":7071"
    echo "Web Client: https://"$2
    exit
}
# Calling Functions
bind
bind_config
zimbra_config
answer
zimbra
restart
enable
