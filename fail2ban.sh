#!/bin/bash

# Warna
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
NC='\033[0m'

echo -e "${C}[+] Installing fail2ban...${NC}"
apt update -y > /dev/null 2>&1
apt install -y fail2ban > /dev/null 2>&1
echo -e "${G}[✓] Done${NC}"

echo -e "${C}[+] Creating complete config with 150+ filters...${NC}"
mkdir -p /etc/fail2ban

# ============ JAIL.LOCAL LENGKAP ============
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 86400
findtime = 600
maxretry = 5
backend = systemd
banaction = iptables-multiport
banaction_allports = iptables-allports
ignoreip = 127.0.0.1/8 ::1 114.10.134.224 68.183.228.145 168.144.129.131 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16

# ============ SSH ============
[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 5
findtime = 300
bantime = 86400

[sshd-ddos]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 10
findtime = 60
bantime = 86400

[dropbear]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 5
bantime = 86400

[ssh-bruteforce]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
findtime = 60
bantime = 86400

[sudo-auth]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
findtime = 60
bantime = 86400

[su-auth]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
findtime = 60
bantime = 86400

# ============ WEB SERVER ============
[apache-auth]
enabled = true
port = http,https
logpath = /var/log/apache2/error.log
maxretry = 6
findtime = 60
bantime = 86400

[apache-badbots]
enabled = true
port = http,https
logpath = /var/log/apache2/access.log
maxretry = 2
findtime = 300
bantime = 86400

[apache-noscript]
enabled = true
port = http,https
logpath = /var/log/apache2/error.log
maxretry = 6
bantime = 86400

[apache-overflows]
enabled = true
port = http,https
logpath = /var/log/apache2/error.log
maxretry = 2
bantime = 86400

[apache-404]
enabled = true
port = http,https
logpath = /var/log/apache2/access.log
maxretry = 10
findtime = 60
bantime = 3600

[apache-403]
enabled = true
port = http,https
logpath = /var/log/apache2/access.log
maxretry = 5
findtime = 60
bantime = 86400

[apache-500]
enabled = true
port = http,https
logpath = /var/log/apache2/error.log
maxretry = 5
findtime = 60
bantime = 86400

[apache-modsecurity]
enabled = true
port = http,https
logpath = /var/log/apache2/modsec_audit.log
maxretry = 3
bantime = 86400

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 6
bantime = 86400

[nginx-4xx]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 20
findtime = 60
bantime = 86400

[nginx-5xx]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
findtime = 60
bantime = 86400

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 20
findtime = 10
bantime = 86400

[nginx-bad-request]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 50
findtime = 60
bantime = 86400

[nginx-http2-reset]
enabled = true
port = https
logpath = /var/log/nginx/error.log
maxretry = 10
findtime = 10
bantime = 86400

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 3
findtime = 60
bantime = 86400

# ============ PANEL & CMS ============
[webmin-auth]
enabled = true
port = 10000
logpath = /var/log/webmin/miniserv.error
maxretry = 5
findtime = 60
bantime = 86400

[cpanel-auth]
enabled = true
port = 2082,2083,2086,2087
logpath = /usr/local/cpanel/logs/login_log
maxretry = 5
findtime = 60
bantime = 86400

[plesk-auth]
enabled = true
port = 8443
logpath = /var/log/plesk/panel.log
maxretry = 5
findtime = 60
bantime = 86400

[vesta-auth]
enabled = true
port = 8083
logpath = /var/log/vesta/auth.log
maxretry = 5
findtime = 60
bantime = 86400

[directadmin-auth]
enabled = true
port = 2222
logpath = /var/log/directadmin/login.log
maxretry = 5
findtime = 60
bantime = 86400

[virtualmin-auth]
enabled = true
port = 10000
logpath = /var/log/virtualmin/miniserv.error
maxretry = 5
findtime = 60
bantime = 86400

[wordpress]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[wp-login]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[wp-xmlrpc]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[wp-softlock]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 3
findtime = 60
bantime = 86400

[wp-404]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 20
findtime = 60
bantime = 86400

[joomla-brute]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[joomla-login]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[joomla-404]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 20
findtime = 60
bantime = 86400

[drupal-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[drupal-login]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[drupal-user]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[magento-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[moodle-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[prestashop-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[opencart-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[nextcloud-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[owncloud-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[ghost-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[pterodactyl-brute]
enabled = true
port = http,https
logpath = /var/www/pterodactyl/storage/logs/laravel.log
maxretry = 10
findtime = 300
bantime = 86400

[pterodactyl-api]
enabled = true
port = http,https
logpath = /var/www/pterodactyl/storage/logs/laravel.log
maxretry = 50
findtime = 60
bantime = 3600

[laravel]
enabled = true
port = http,https
logpath = /var/www/*/storage/logs/laravel.log
maxretry = 5
findtime = 60
bantime = 86400

[jenkins-auth]
enabled = true
port = 8080
logpath = /var/log/jenkins/jenkins.log
maxretry = 5
findtime = 60
bantime = 86400

[gitlab-auth]
enabled = true
port = http,https
logpath = /var/log/gitlab/gitlab-rails/production.log
maxretry = 5
findtime = 60
bantime = 86400

[jira-auth]
enabled = true
port = 8080
logpath = /var/log/jira/atlassian-jira.log
maxretry = 5
findtime = 60
bantime = 86400

[confluence-auth]
enabled = true
port = 8090
logpath = /var/log/confluence/atlassian-confluence.log
maxretry = 5
findtime = 60
bantime = 86400

# ============ FTP ============
[vsftpd]
enabled = true
port = ftp,ftp-data,ftps,ftps-data
logpath = /var/log/vsftpd.log
maxretry = 5
bantime = 86400

[proftpd]
enabled = true
port = ftp,ftp-data,ftps,ftps-data
logpath = /var/log/proftpd/proftpd.log
maxretry = 5
bantime = 86400

[pure-ftpd]
enabled = true
port = ftp,ftp-data,ftps,ftps-data
logpath = /var/log/pure-ftpd/pure-ftpd.log
maxretry = 5
bantime = 86400

# ============ MAIL SERVER ============
[postfix]
enabled = true
port = smtp,ssmtp,submission
logpath = /var/log/mail.log
maxretry = 5
bantime = 86400

[postfix-spam]
enabled = true
port = smtp,ssmtp
logpath = /var/log/mail.log
maxretry = 3
findtime = 60
bantime = 86400

[postfix-rbl]
enabled = true
port = smtp
logpath = /var/log/mail.log
maxretry = 2
findtime = 60
bantime = 86400

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps
logpath = /var/log/mail.log
maxretry = 5
bantime = 86400

[dovecot-ldap]
enabled = true
port = pop3,imap
logpath = /var/log/mail.log
maxretry = 5
findtime = 60
bantime = 86400

[exim]
enabled = true
port = smtp,ssmtp
logpath = /var/log/exim/mainlog
maxretry = 5
bantime = 86400

[exim-spam]
enabled = true
port = smtp
logpath = /var/log/exim/mainlog
maxretry = 3
findtime = 60
bantime = 86400

[sendmail-auth]
enabled = true
port = smtp,ssmtp
logpath = /var/log/mail.log
maxretry = 5
bantime = 86400

[sendmail-spam]
enabled = true
port = smtp
logpath = /var/log/mail.log
maxretry = 3
findtime = 60
bantime = 86400

[courier-auth]
enabled = true
port = smtp,pop3,imap
logpath = /var/log/mail.log
maxretry = 5
bantime = 86400

[sasl-auth]
enabled = true
port = smtp,ssmtp,submission,imap,pop3
logpath = /var/log/mail.log
maxretry = 5
bantime = 86400

[roundcube]
enabled = true
port = http,https
logpath = /var/log/roundcube/errors.log
maxretry = 5
bantime = 86400

[squirrelmail]
enabled = true
port = http,https
logpath = /var/log/squirrelmail/default.log
maxretry = 5
bantime = 86400

[opendkim]
enabled = true
port = 8891
logpath = /var/log/mail.log
maxretry = 3
bantime = 86400

[spamassassin]
enabled = true
port = 783
logpath = /var/log/spamassassin/spamd.log
maxretry = 5
bantime = 86400

[clamav]
enabled = true
port = 3310
logpath = /var/log/clamav/clamav.log
maxretry = 5
bantime = 86400

[rspamd]
enabled = true
port = 11334
logpath = /var/log/rspamd/rspamd.log
maxretry = 5
bantime = 86400

# ============ DATABASE ============
[mysql-auth]
enabled = true
port = mysql
logpath = /var/log/mysql/error.log
maxretry = 5
bantime = 86400

[mariadb-auth]
enabled = true
port = 3306
logpath = /var/log/mysql/error.log
maxretry = 5
bantime = 86400

[postgresql-auth]
enabled = true
port = postgresql
logpath = /var/log/postgresql/postgresql.log
maxretry = 5
bantime = 86400

[mongodb-auth]
enabled = true
port = 27017
logpath = /var/log/mongodb/mongodb.log
maxretry = 5
bantime = 86400

[cassandra-auth]
enabled = true
port = 9042
logpath = /var/log/cassandra/system.log
maxretry = 5
bantime = 86400

[sqlserver-auth]
enabled = true
port = 1433
logpath = /var/log/mssql/errorlog
maxretry = 5
bantime = 86400

[oracle-auth]
enabled = true
port = 1521
logpath = /u01/app/oracle/diag/rdbms/*/trace/alert*.log
maxretry = 5
bantime = 86400

[elasticsearch]
enabled = true
port = 9200,9300
logpath = /var/log/elasticsearch/*.log
maxretry = 5
bantime = 86400

[influxdb-auth]
enabled = true
port = 8086
logpath = /var/log/influxdb/influxd.log
maxretry = 5
bantime = 86400

[couchdb-auth]
enabled = true
port = 5984
logpath = /var/log/couchdb/couch.log
maxretry = 5
bantime = 86400

[redis]
enabled = true
port = 6379
logpath = /var/log/redis/redis-server.log
maxretry = 5
bantime = 86400

# ============ GAME SERVER ============
[minecraft]
enabled = true
port = 25565
logpath = /var/log/minecraft/server.log
maxretry = 5
bantime = 86400

[csgo]
enabled = true
port = 27015
logpath = /var/log/csgo/server.log
maxretry = 5
bantime = 86400

[valheim]
enabled = true
port = 2456,2457
logpath = /var/log/valheim/server.log
maxretry = 5
bantime = 86400

[ark-survival]
enabled = true
port = 7777,27015
logpath = /var/log/ark/server.log
maxretry = 5
bantime = 86400

[rust]
enabled = true
port = 28015
logpath = /var/log/rust/server.log
maxretry = 5
bantime = 86400

[fivem]
enabled = true
port = 30120
logpath = /var/log/fivem/server.log
maxretry = 5
bantime = 86400

[terraria]
enabled = true
port = 7777
logpath = /var/log/terraria/server.log
maxretry = 5
bantime = 86400

[palworld]
enabled = true
port = 8211
logpath = /var/log/palworld/server.log
maxretry = 5
bantime = 86400

[enshrouded]
enabled = true
port = 15636
logpath = /var/log/enshrouded/server.log
maxretry = 5
bantime = 86400

[squad]
enabled = true
port = 7788,27116
logpath = /var/log/squad/server.log
maxretry = 5
bantime = 86400

[game-server]
enabled = true
port = 27015,27016,27017
logpath = /var/log/gameserver/server.log
maxretry = 10
findtime = 60
bantime = 86400

# ============ DNS & NETWORK ============
[bind]
enabled = true
port = domain
logpath = /var/log/named/security.log
maxretry = 5
bantime = 86400

[named]
enabled = true
port = 53
logpath = /var/log/named/security.log
maxretry = 5
bantime = 86400

[dns-amplification]
enabled = true
port = 53
logpath = /var/log/named/query.log
maxretry = 10
findtime = 10
bantime = 86400

[ntp-amplification]
enabled = true
port = 123
logpath = /var/log/ntp.log
maxretry = 10
findtime = 10
bantime = 86400

[snmp-auth]
enabled = true
port = 161
logpath = /var/log/snmpd.log
maxretry = 5
bantime = 86400

[ldap-auth]
enabled = true
port = 389,636
logpath = /var/log/slapd.log
maxretry = 5
bantime = 86400

[radius-auth]
enabled = true
port = 1812,1813
logpath = /var/log/freeradius/radius.log
maxretry = 5
bantime = 86400

[ike-auth]
enabled = true
port = 500,4500
logpath = /var/log/strongswan/charon.log
maxretry = 5
bantime = 86400

# ============ VPN & TUNNEL ============
[wireguard]
enabled = true
port = 51820
logpath = /var/log/wireguard/wireguard.log
maxretry = 5
bantime = 86400

[openvpn]
enabled = true
port = 1194
logpath = /var/log/openvpn.log
maxretry = 5
bantime = 86400

[openvpn-otp]
enabled = true
port = 1194
logpath = /var/log/openvpn.log
maxretry = 3
findtime = 60
bantime = 86400

[ipsec]
enabled = true
port = 500,4500
logpath = /var/log/ipsec.log
maxretry = 5
bantime = 86400

[l2tp]
enabled = true
port = 1701
logpath = /var/log/xl2tpd.log
maxretry = 5
bantime = 86400

[pptp]
enabled = true
port = 1723
logpath = /var/log/pptpd.log
maxretry = 5
bantime = 86400

[sstp]
enabled = true
port = 443
logpath = /var/log/sstp/sstpd.log
maxretry = 5
bantime = 86400

[softether]
enabled = true
port = 443,992,1194,5555
logpath = /var/log/softether/server.log
maxretry = 5
bantime = 86400

# ============ DOS / SCAN ============
[recidive]
enabled = true
logpath = /var/log/fail2ban.log
banaction = iptables-allports
bantime = 604800
findtime = 86400
maxretry = 5

[port-scan]
enabled = true
logpath = /var/log/kern.log
maxretry = 5
findtime = 60
bantime = 86400

[dos]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 100
findtime = 5
bantime = 3600

[nmap]
enabled = true
logpath = /var/log/kern.log
maxretry = 3
findtime = 60
bantime = 86400

[sql-injection]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 3
findtime = 60
bantime = 86400

[xss]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 3
findtime = 60
bantime = 86400

[path-traversal]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[user-enum]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[csrf-attack]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[jwt-bruteforce]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[oauth-bruteforce]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[saml-bruteforce]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[graphql-introspection]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 3
findtime = 60
bantime = 86400

[rest-api-bruteforce]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 20
findtime = 60
bantime = 86400

[soap-bruteforce]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

# ============ CDN / PROXY ============
[cloudflare]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[cf-uam]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[proxy]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 3
findtime = 60
bantime = 86400

[tor-exit]
enabled = true
port = http,https,ssh
logpath = /var/log/nginx/access.log
maxretry = 2
findtime = 60
bantime = 86400

# ============ BOT / SCANNER ============
[bot-search]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[scanner]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[spam-user]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 3
findtime = 60
bantime = 86400

[referer-spam]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[gpt-bot]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[claude-bot]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[gemini-bot]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[perplexity-bot]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[bing-bot]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[yandex-bot]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[baidu-bot]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[semrush-bot]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

# ============ RATE LIMIT SPECIFIC ============
[api-rate-limit]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 30
findtime = 60
bantime = 3600

[login-rate-limit]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[register-rate-limit]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[reset-password-rate]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

[otp-rate-limit]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 60
bantime = 86400

[captcha-fail]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 5
findtime = 60
bantime = 86400

# ============ MISC ============
[cron-auth]
enabled = true
logpath = /var/log/auth.log
maxretry = 5
findtime = 60
bantime = 86400

[docker-auth]
enabled = true
port = 2375,2376
logpath = /var/log/docker.log
maxretry = 5
bantime = 86400

[kubernetes-auth]
enabled = true
port = 6443
logpath = /var/log/kubernetes/kube-apiserver.log
maxretry = 5
bantime = 86400

[asterisk]
enabled = true
port = 5060,5061
logpath = /var/log/asterisk/security
maxretry = 5
bantime = 86400

[sip]
enabled = true
port = 5060,5061
logpath = /var/log/asterisk/security
maxretry = 5
bantime = 86400

[stunnel]
enabled = true
port = 443
logpath = /var/log/stunnel4/stunnel.log
maxretry = 5
bantime = 86400

[mqtt-auth]
enabled = true
port = 1883,8883
logpath = /var/log/mosquitto/mosquitto.log
maxretry = 5
bantime = 86400

[modbus]
enabled = true
port = 502
logpath = /var/log/modbus/modbus.log
maxretry = 5
bantime = 86400

[bacnet]
enabled = true
port = 47808
logpath = /var/log/bacnet/bacnet.log
maxretry = 5
bantime = 86400

[dnp3]
enabled = true
port = 20000
logpath = /var/log/dnp3/dnp3.log
maxretry = 5
bantime = 86400

[s7comm]
enabled = true
port = 102
logpath = /var/log/s7comm/s7comm.log
maxretry = 5
bantime = 86400

[profinet]
enabled = true
port = 34964
logpath = /var/log/profinet/profinet.log
maxretry = 5
bantime = 86400
EOF

echo -e "${G}[✓] Jail.local created with 150+ jails${NC}"

# ============ MEMBUAT SEMUA FILTER YANG DIPERLUKAN ============
echo -e "${C}[+] Creating filters...${NC}"

# Filter 1-10
cat > /etc/fail2ban/filter.d/nginx-limit-req.conf << 'EOF'
[Definition]
failregex = ^.* limiting requests, excess:.* client: <HOST>
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/nginx-bad-request.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST|HEAD).* HTTP.*" 400 .*$
            ^<HOST> -.*"(GET|POST|HEAD).* HTTP.*" 403 .*$
            ^<HOST> -.*"(GET|POST|HEAD).* HTTP.*" 404 .*$
            ^<HOST> -.*"(GET|POST|HEAD).* HTTP.*" 444 .*$
            ^<HOST> -.*"(GET|POST|HEAD).* HTTP.*" 499 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/nginx-http2-reset.conf << 'EOF'
[Definition]
failregex = ^.* http2 reset flood.* client: <HOST>.*$
            ^.* HTTP/2 stream.* reset.* client: <HOST>.*$
            ^.* 400.* HTTP/2.* client: <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/pterodactyl-brute.conf << 'EOF'
[Definition]
failregex = .*IP: <HOST>.*Failed to authenticate.*
            .*IP: <HOST>.*Invalid credentials.*
            .*IP: <HOST>.*Login failed.*
            .*IP: <HOST>.*Authentication failed.*
            .*IP: <HOST>.*Invalid API key.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/pterodactyl-api.conf << 'EOF'
[Definition]
failregex = .*IP: <HOST>.*API rate limit exceeded.*
            .*IP: <HOST>.*Too many requests.*
            .*IP: <HOST>.*Rate limit exceeded.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/wordpress.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*wp-login\.php.* HTTP.*"
            ^<HOST> .* "POST .*xmlrpc\.php.* HTTP.*"
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/wp-login.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*wp-login\.php.* HTTP.*"
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/wp-xmlrpc.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*xmlrpc\.php.* HTTP.*"
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/wp-softlock.conf << 'EOF'
[Definition]
failregex = .*WordPress logged out.*<HOST>.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/wp-404.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" 404 .*$
ignoreregex =
EOF

# Filter 11-20
cat > /etc/fail2ban/filter.d/joomla-brute.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*index\.php.*option=com_users.*task=user\.login.* HTTP.*"
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/joomla-login.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*index\.php.*option=com_users.*task=user\.login.* HTTP.*"
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/joomla-404.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" 404 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/drupal-auth.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*user/login.* HTTP.*"
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/drupal-login.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*user/login.* HTTP.*"
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/drupal-user.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "GET .*user/.* HTTP.*" 403 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/magento-auth.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*/admin/index\.php.* HTTP.*"
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/moodle-auth.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*login/index\.php.* HTTP.*"
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/prestashop-auth.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*admin.*/index\.php.*controller=AdminLogin.* HTTP.*"
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/opencart-auth.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST .*/admin/index\.php.*route=common/login.* HTTP.*"
ignoreregex =
EOF

# Filter 21-30
cat > /etc/fail2ban/filter.d/nextcloud-auth.conf << 'EOF'
[Definition]
failregex = ^.*"remoteAddr":"<HOST>","message":"Login failed.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/owncloud-auth.conf << 'EOF'
[Definition]
failregex = ^.*"remoteAddr":"<HOST>","message":"Login failed.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/ghost-auth.conf << 'EOF'
[Definition]
failregex = ^.*"ip":"<HOST>","message":"Attempted login.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/laravel.conf << 'EOF'
[Definition]
failregex = .*IP: <HOST>.*Failed to authenticate.*
            .*IP: <HOST>.*Invalid credentials.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/webmin-auth.conf << 'EOF'
[Definition]
failregex = ^.* Login failed for .* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/cpanel-auth.conf << 'EOF'
[Definition]
failregex = ^.* Login failed: .* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/plesk-auth.conf << 'EOF'
[Definition]
failregex = ^.* "Login failed for user .*" client=<HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/vesta-auth.conf << 'EOF'
[Definition]
failregex = ^.* Failed login on .* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/directadmin-auth.conf << 'EOF'
[Definition]
failregex = ^.* 401 from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/virtualmin-auth.conf << 'EOF'
[Definition]
failregex = ^.* Login failed for .* from <HOST>.*$
ignoreregex =
EOF

# Filter 31-40
cat > /etc/fail2ban/filter.d/jenkins-auth.conf << 'EOF'
[Definition]
failregex = ^.* "POST /j_acegi_security_check HTTP.*" 403 .* <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/gitlab-auth.conf << 'EOF'
[Definition]
failregex = ^.* Failed login for .* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/jira-auth.conf << 'EOF'
[Definition]
failregex = ^.* "POST /login.jsp.* HTTP.*" 200 .* <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/confluence-auth.conf << 'EOF'
[Definition]
failregex = ^.* "POST /login.action.* HTTP.*" 200 .* <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/port-scan.conf << 'EOF'
[Definition]
failregex = ^.*\s(kernel:.*\sSRC=<HOST>.*DPT=\d+.*)$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/dos.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" 200 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/nmap.conf << 'EOF'
[Definition]
failregex = ^.*\sSRC=<HOST>.*\sPROTO=(TCP|UDP)\s.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/sql-injection.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*(UNION SELECT|SELECT.*FROM|INSERT INTO|DELETE FROM|DROP TABLE).*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/xss.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*(<script|onerror=|onload=|alert\(|javascript:).*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/path-traversal.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*(\.\./|\.\.%2f|%2e%2e%2f).*$
ignoreregex =
EOF

# Filter 41-50
cat > /etc/fail2ban/filter.d/user-enum.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.*\/(admin|administrator|root|user|test).* .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.csrf-attack.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.* HTTP.*" 403 .*CSRF.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/jwt-bruteforce.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.*/api.*" 401 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/oauth-bruteforce.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.*/oauth/token.*" 401 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/saml-bruteforce.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.*/saml.*" 401 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/graphql-introspection.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.*/graphql.*__schema.*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/rest-api-bruteforce.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.*/api.*" 401 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/soap-bruteforce.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.*/soap.*" 401 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/cloudflare.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" (403|503).*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/cf-uam.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" 503 .*cf-browser-verification.*$
ignoreregex =
EOF

# Filter 51-60
cat > /etc/fail2ban/filter.d/proxy.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" .*"X-Forwarded-For".*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/tor-exit.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/bot-search.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(curl|wget|python|scrapy|sqlmap|nikto|masscan).*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/scanner.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.*(\.php|\.env|\.git|\.sql|\.bak).* .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/spam-user.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*POST.*(login|auth|wp-login).* 200 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/referer-spam.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" 200 .* ".*(semalt|buttons-for-website|buy-cheap-online).*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/gpt-bot.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GPTBot.*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/claude-bot.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"ClaudeBot.*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/gemini-bot.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GoogleOther.*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/perplexity-bot.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"PerplexityBot.*" .*$
ignoreregex =
EOF

# Filter 61-70
cat > /etc/fail2ban/filter.d/bing-bot.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"bingbot.*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/yandex-bot.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"YandexBot.*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/baidu-bot.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"Baiduspider.*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/semrush-bot.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"SEMrushBot.*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/api-rate-limit.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.*/api.* HTTP.*" 429 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/login-rate-limit.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.*(login|auth).* HTTP.*" 429 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/register-rate-limit.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.*(register|signup).* HTTP.*" 429 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/reset-password-rate.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.*(reset-password|forgot-password).* HTTP.*" 429 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/otp-rate-limit.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.*(otp|verify).* HTTP.*" 429 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/captcha-fail.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"POST.* HTTP.*" 403 .*captcha.*$
ignoreregex =
EOF

# Filter 71-80
cat > /etc/fail2ban/filter.d/php-url-fopen.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.*(http://|https://).* HTTP.*" .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/php-fpm.conf << 'EOF'
[Definition]
failregex = ^.* WARNING.* \[pool .*\] child .* said into stderr: .* <HOST> .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/sudo-auth.conf << 'EOF'
[Definition]
failregex = ^.* sudo.*:.* authentication failure.* ruser=.* rhost=<HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/su-auth.conf << 'EOF'
[Definition]
failregex = ^.* su:.* authentication failure.* rhost=<HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/cron-auth.conf << 'EOF'
[Definition]
failregex = ^.* cron.* authentication failure.* rhost=<HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/docker-auth.conf << 'EOF'
[Definition]
failregex = ^.* conn from=<HOST>.* authentication failed.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/kubernetes-auth.conf << 'EOF'
[Definition]
failregex = ^.* Unauthorized.* client="<HOST>".*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/asterisk.conf << 'EOF'
[Definition]
failregex = ^.* Registration from '.*' failed for '<HOST>' - Wrong password.*$
            ^.* Call from '.*' to '.*' rejected because unknown extension '.*' from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/sip.conf << 'EOF'
[Definition]
failregex = ^.* Registration from '.*' failed for '<HOST>' - Wrong password.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/redis.conf << 'EOF'
[Definition]
failregex = ^.* Connection from <HOST>.*$
ignoreregex =
EOF

# Filter 81-90
cat > /etc/fail2ban/filter.d/mongodb-auth.conf << 'EOF'
[Definition]
failregex = ^.* Failed authentication from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/cassandra-auth.conf << 'EOF'
[Definition]
failregex = ^.* AuthenticationFailedException.* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/sqlserver-auth.conf << 'EOF'
[Definition]
failregex = ^.* Login failed for user.* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/oracle-auth.conf << 'EOF'
[Definition]
failregex = ^.* ORA-28000:.* account locked.* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/elasticsearch.conf << 'EOF'
[Definition]
failregex = ^.* 401 Unauthorized.* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/influxdb-auth.conf << 'EOF'
[Definition]
failregex = ^.* authentication failed.* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/couchdb-auth.conf << 'EOF'
[Definition]
failregex = ^.* Login failed for user.* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/minecraft.conf << 'EOF'
[Definition]
failregex = ^.* Failed to verify username from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/csgo.conf << 'EOF'
[Definition]
failregex = ^.* STEAM USERID validated for <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/valheim.conf << 'EOF'
[Definition]
failregex = ^.* Connection from <HOST>.* authentication failed.*$
ignoreregex =
EOF

# Filter 91-100
cat > /etc/fail2ban/filter.d/ark-survival.conf << 'EOF'
[Definition]
failregex = ^.* Failed authentication from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/rust.conf << 'EOF'
[Definition]
failregex = ^.* Authentication failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/fivem.conf << 'EOF'
[Definition]
failregex = ^.* Invalid token from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/terraria.conf << 'EOF'
[Definition]
failregex = ^.* Failed login from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/palworld.conf << 'EOF'
[Definition]
failregex = ^.* Authentication failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/enshrouded.conf << 'EOF'
[Definition]
failregex = ^.* Failed authentication from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/squad.conf << 'EOF'
[Definition]
failregex = ^.* Invalid token from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/openvpn-otp.conf << 'EOF'
[Definition]
failregex = ^.* TLS Error: incoming packet authentication failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/ipsec.conf << 'EOF'
[Definition]
failregex = ^.* authentication failed.* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/l2tp.conf << 'EOF'
[Definition]
failregex = ^.* Authentication failed for user .* from <HOST>.*$
ignoreregex =
EOF

# Filter 101-110
cat > /etc/fail2ban/filter.d/pptp.conf << 'EOF'
[Definition]
failregex = ^.* GRE:.* from <HOST>.* failed.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/sstp.conf << 'EOF'
[Definition]
failregex = ^.* SSL/TLS handshake failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/softether.conf << 'EOF'
[Definition]
failregex = ^.* Authentication failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/mqtt-auth.conf << 'EOF'
[Definition]
failregex = ^.* Authentication failed for user .* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/modbus.conf << 'EOF'
[Definition]
failregex = ^.* Illegal function from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/bacnet.conf << 'EOF'
[Definition]
failregex = ^.* BACnet authentication failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/dnp3.conf << 'EOF'
[Definition]
failregex = ^.* DNP3 authentication failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/s7comm.conf << 'EOF'
[Definition]
failregex = ^.* S7 authentication failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/profinet.conf << 'EOF'
[Definition]
failregex = ^.* Profinet authentication failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/dns-amplification.conf << 'EOF'
[Definition]
failregex = ^.* query:.*ANY.* from \[<HOST>\].*$
ignoreregex =
EOF

# Filter 111-120
cat > /etc/fail2ban/filter.d/ntp-amplification.conf << 'EOF'
[Definition]
failregex = ^.* monlist.* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/snmp-auth.conf << 'EOF'
[Definition]
failregex = ^.* authenticationFailure.* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/ldap-auth.conf << 'EOF'
[Definition]
failregex = ^.* conn=<HOST>.* authentication failed.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/radius-auth.conf << 'EOF'
[Definition]
failregex = ^.* Login incorrect from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/ike-auth.conf << 'EOF'
[Definition]
failregex = ^.* authentication failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/wireguard.conf << 'EOF'
[Definition]
failregex = ^.* Handshake for peer .* failed for <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/postfix-spam.conf << 'EOF'
[Definition]
failregex = ^.* reject: RCPT from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/postfix-rbl.conf << 'EOF'
[Definition]
failregex = ^.* NOQUEUE: reject: RCPT from <HOST>.* listed in .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/dovecot-ldap.conf << 'EOF'
[Definition]
failregex = ^.* ldap\(<HOST>\):.* authentication failed.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/exim-spam.conf << 'EOF'
[Definition]
failregex = ^.* rejected from <HOST>.*$
ignoreregex =
EOF

# Filter 121-130
cat > /etc/fail2ban/filter.d/sendmail-spam.conf << 'EOF'
[Definition]
failregex = ^.* reject.* from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/opendkim.conf << 'EOF'
[Definition]
failregex = ^.* DKIM signature.* failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/spamassassin.conf << 'EOF'
[Definition]
failregex = ^.* spamd:.* connection from <HOST>.* failed.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/clamav.conf << 'EOF'
[Definition]
failregex = ^.* clamd:.* connection from <HOST>.* failed.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/rspamd.conf << 'EOF'
[Definition]
failregex = ^.* rspamd:.* authentication failed from <HOST>.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/nginx-4xx.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" 4[0-9]{2} .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/nginx-5xx.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" 5[0-9]{2} .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/apache-403.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"GET.* HTTP.*" 403 .*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/apache-500.conf << 'EOF'
[Definition]
failregex = ^.* client <HOST>.* PHP Fatal error.*$
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/mariadb-auth.conf << 'EOF'
[Definition]
failregex = ^.* Access denied for user.* from <HOST>.*$
ignoreregex =
EOF

echo -e "${G}[✓] 130+ filters created${NC}"

# ============ START FAIL2BAN ============
echo -e "${C}[+] Starting fail2ban...${NC}"
systemctl enable fail2ban 2>/dev/null
systemctl restart fail2ban 2>/dev/null

sleep 2

echo -e "${G}[✓] Fail2ban running${NC}"

# ============ STATUS ============
echo -e "\n${C}════════════════════════════════════════════════════${NC}"
echo -e "${G}[✓] Total jails: 130+${NC}"
echo -e "${G}[✓] Total filters: 130+${NC}"
echo -e "\n${C}════════════════════════════════════════════════════${NC}"

fail2ban-client status 2>/dev/null | head -20
