#!/bin/bash
DIR="/var/www/pterodactyl/public"
if [ ! -d "$DIR" ]; then
  DIR=$(find /var/www -type d -name "public" 2>/dev/null | grep "pterodactyl" | head -n 1 || true)
fi

[ -z "${DIR:-}" ] && exit 1
cd "$DIR" 2>/dev/null || exit 1

if [ -f "index.php" ] && [ ! -f "index.php.bak" ]; then
  cp index.php index.php.bak
  echo "✅ Backup created: $DIR/index.php.bak"
elif [ -f "index.php" ] && [ -f "index.php.bak" ]; then
  echo "✅ Backup already exists, skipping backup"
else
  echo "❌ index.php not found in $DIR"
  exit 1
fi

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
[ -z "$INTERFACE" ] && INTERFACE="eth0"

apt update -y
apt install -y iptables iptables-persistent netfilter-persistent ipset conntrack ufw fail2ban curl dnsutils net-tools wondershaper trickle php-curl rsyslog

systemctl enable rsyslog 2>/dev/null || true
systemctl restart rsyslog 2>/dev/null || true

modprobe ip_tables 2>/dev/null || true
modprobe iptable_filter 2>/dev/null || true
modprobe iptable_nat 2>/dev/null || true
modprobe nf_conntrack 2>/dev/null || true
modprobe br_netfilter 2>/dev/null || true
modprobe xt_SYNPROXY 2>/dev/null || true

systemctl enable docker 2>/dev/null || true
systemctl restart docker 2>/dev/null || true

iptables -N DOCKER-USER 2>/dev/null || true
iptables -F DOCKER-USER 2>/dev/null || true
iptables -A DOCKER-USER -j RETURN 2>/dev/null || true

touch /var/log/file.log
chmod 644 /var/log/file.log

BAN_LOG="/var/log/ban.log"
touch $BAN_LOG
chmod 644 $BAN_LOG

ipset create whitelist hash:ip -exist
ipset create whitelist6 hash:ip -exist 2>/dev/null || true

WHITELIST_IPS=("114.10.134.224" "68.183.228.145" "168.144.129.131")
for ip in "${WHITELIST_IPS[@]}"; do
    ipset add whitelist $ip -exist 2>/dev/null
done

VPS_IP=$(curl -s ifconfig.me 2>/dev/null)
[ -n "$VPS_IP" ] && ipset add whitelist $VPS_IP -exist 2>/dev/null

iptables -I INPUT -s 127.0.0.1 -j ACCEPT
iptables -I INPUT -s 10.0.0.0/8 -j ACCEPT
iptables -I INPUT -s 172.16.0.0/12 -j ACCEPT
iptables -I INPUT -s 192.168.0.0/16 -j ACCEPT
iptables -I INPUT -i docker0 -j ACCEPT 2>/dev/null || true
iptables -I INPUT -i br-+ -j ACCEPT 2>/dev/null || true

cat > /etc/sysctl.d/99-hardening.conf << 'EOF'
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=1
net.ipv4.tcp_max_syn_backlog=65536
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_max_tw_buckets=200000
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.core.somaxconn=65535
net.core.netdev_max_backlog=65535
net.netfilter.nf_conntrack_max=4194304
net.netfilter.nf_conntrack_tcp_timeout_established=180
net.netfilter.nf_conntrack_udp_timeout=10
net.netfilter.nf_conntrack_icmp_timeout=5
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
kernel.randomize_va_space=2
kernel.kptr_restrict=1
kernel.dmesg_restrict=1
fs.protected_symlinks=1
fs.protected_hardlinks=1
fs.suid_dumpable=0
EOF

sysctl --system >/dev/null 2>&1

mkdir -p /etc/fail2ban

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 86400
findtime = 600
maxretry = 5
backend = systemd
banaction = iptables-multiport
banaction_allports = iptables-allports
ignoreip = 127.0.0.1/8 ::1 114.10.134.224 68.183.228.145 168.144.129.131 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16

[sshd]
enabled = true
port = 22
mode = aggressive
maxretry = 10
findtime = 600
bantime = 86400

[sshd-ddos]
enabled = true
port = 22
maxretry = 20
findtime = 60
bantime = 86400
logpath = /var/log/auth.log

[recidive]
enabled = true
logpath = /var/log/fail2ban.log
banaction = iptables-allports
bantime = 604800
findtime = 86400
maxretry = 15

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
failregex = ^.* http2 reset flood.* client: <HOST>.*$
            ^.* HTTP/2 stream.* reset.* client: <HOST>.*$
            ^.* 400.* HTTP/2.* client: <HOST>.*$
maxretry = 10
findtime = 10
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
EOF

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

systemctl enable fail2ban 2>/dev/null || true
systemctl restart fail2ban 2>/dev/null || true

ipset create blacklist hash:ip timeout 86400 -exist
ipset create blacklist_udp hash:ip timeout 3600 -exist
ipset create blacklist_tcp hash:ip timeout 3600 -exist
ipset create udp_flood hash:ip timeout 300 -exist
ipset create tcp_flood hash:ip timeout 300 -exist
ipset create autoban hash:ip timeout 86400 -exist

log_ban_ip() {
    local ip=$1
    local reason=$2
    if [ -n "$ip" ] && ! grep -qx "$ip" "$BAN_LOG" 2>/dev/null; then
        echo "$ip" >> "$BAN_LOG"
        logger -t "firewall-ban" "BANNED IP: $ip | Reason: $reason"
    fi
}

iptables -F INPUT
iptables -F FORWARD
iptables -F OUTPUT
iptables -t mangle -F

iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

iptables -A INPUT -m set --match-set whitelist src -j ACCEPT

iptables -A INPUT -m set --match-set blacklist src -j DROP
iptables -A INPUT -m set --match-set blacklist_udp src -j DROP
iptables -A INPUT -m set --match-set blacklist_tcp src -j DROP
iptables -A INPUT -m set --match-set autoban src -j DROP

iptables -A INPUT -f -j LOG --log-prefix "FRAGMENTED_DROP: "
iptables -A INPUT -f -j DROP

iptables -A INPUT -p tcp -m tcp --tcp-flags SYN,ACK SYN,ACK -m string --string "timestamp" --algo bm -j LOG --log-prefix "TCP_TIMESTAMP: "
iptables -A INPUT -p tcp -m tcp --tcp-flags SYN,ACK SYN,ACK -m string --string "timestamp" --algo bm -j DROP

iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m tcpmss --mss 1:500 -j LOG --log-prefix "MSS_TOO_LOW: "
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m tcpmss --mss 1:500 -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m tcpmss --mss 9000:65535 -j LOG --log-prefix "MSS_TOO_HIGH: "
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m tcpmss --mss 9000:65535 -j DROP
iptables -A FORWARD -p tcp --tcp-flags SYN,ACK SYN,ACK -m tcpmss --mss 1:500 -j DROP
iptables -A FORWARD -p tcp --tcp-flags SYN,ACK SYN,ACK -m tcpmss --mss 9000:65535 -j DROP

iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m ecn --ecn-tcp-cwr -j LOG --log-prefix "ECN_CWR: "
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m ecn --ecn-tcp-cwr -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m ecn --ecn-tcp-ece -j LOG --log-prefix "ECN_ECE: "
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m ecn --ecn-tcp-ece -j DROP

iptables -A INPUT -p tcp -m length --length 0:100 -j ACCEPT
iptables -A INPUT -p tcp -m length --length 100:1500 -j ACCEPT
iptables -A INPUT -p tcp -m length --length 1500:3000 -m limit --limit 5/second --limit-burst 10 -j ACCEPT
iptables -A INPUT -p tcp -m length --length 1500:3000 -j LOG --log-prefix "TCP_SIZE_BAN: "
iptables -A INPUT -p tcp -m length --length 1500:3000 -j SET --add-set autoban src
iptables -A INPUT -p tcp -m length --length 1500:3000 -j DROP
iptables -A INPUT -p tcp -m length --length 3000:65535 -j LOG --log-prefix "TCP_TOO_LARGE: "
iptables -A INPUT -p tcp -m length --length 3000:65535 -j SET --add-set autoban src
iptables -A INPUT -p tcp -m length --length 3000:65535 -j DROP

iptables -A INPUT -p udp -m length --length 0:100 -j ACCEPT
iptables -A INPUT -p udp -m length --length 100:500 -j ACCEPT
iptables -A INPUT -p udp -m length --length 500:1500 -m limit --limit 10/second --limit-burst 20 -j ACCEPT
iptables -A INPUT -p udp -m length --length 500:1500 -j LOG --log-prefix "UDP_SIZE_BAN: "
iptables -A INPUT -p udp -m length --length 500:1500 -j SET --add-set autoban src
iptables -A INPUT -p udp -m length --length 500:1500 -j DROP
iptables -A INPUT -p udp -m length --length 1500:65535 -j LOG --log-prefix "UDP_TOO_LARGE: "
iptables -A INPUT -p udp -m length --length 1500:65535 -j SET --add-set autoban src
iptables -A INPUT -p udp -m length --length 1500:65535 -j DROP

iptables -A INPUT -p tcp --dport 80 -m string --string "POST" --algo bm --to 1000 -m length --length 0:2048 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -m string --string "POST" --algo bm --to 1000 -m length --length 2048:8192 -j LOG --log-prefix "HTTP_POST_LARGE: "
iptables -A INPUT -p tcp --dport 80 -m string --string "POST" --algo bm --to 1000 -m length --length 2048:8192 -j SET --add-set autoban src
iptables -A INPUT -p tcp --dport 80 -m string --string "POST" --algo bm --to 1000 -m length --length 2048:8192 -j DROP
iptables -A INPUT -p tcp --dport 80 -m string --string "POST" --algo bm --to 1000 -m length --length 8192:65535 -j LOG --log-prefix "HTTP_POST_HUGE: "
iptables -A INPUT -p tcp --dport 80 -m string --string "POST" --algo bm --to 1000 -m length --length 8192:65535 -j SET --add-set autoban src
iptables -A INPUT -p tcp --dport 80 -m string --string "POST" --algo bm --to 1000 -m length --length 8192:65535 -j DROP

iptables -A INPUT -p tcp --dport 443 -m string --string "POST" --algo bm --to 1000 -m length --length 0:2048 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m string --string "POST" --algo bm --to 1000 -m length --length 2048:8192 -j LOG --log-prefix "HTTPS_POST_LARGE: "
iptables -A INPUT -p tcp --dport 443 -m string --string "POST" --algo bm --to 1000 -m length --length 2048:8192 -j SET --add-set autoban src
iptables -A INPUT -p tcp --dport 443 -m string --string "POST" --algo bm --to 1000 -m length --length 2048:8192 -j DROP
iptables -A INPUT -p tcp --dport 443 -m string --string "POST" --algo bm --to 1000 -m length --length 8192:65535 -j LOG --log-prefix "HTTPS_POST_HUGE: "
iptables -A INPUT -p tcp --dport 443 -m string --string "POST" --algo bm --to 1000 -m length --length 8192:65535 -j SET --add-set autoban src
iptables -A INPUT -p tcp --dport 443 -m string --string "POST" --algo bm --to 1000 -m length --length 8192:65535 -j DROP

for port in 19 17 111 137 138 139 161 389 1900 11211 3702 5353 5683 3283 5900 7 13 37 53 123; do
    iptables -A INPUT -p udp --dport $port -m limit --limit 5/second --limit-burst 10 -j ACCEPT
    iptables -A INPUT -p udp --dport $port -j LOG --log-prefix "AMP_BAN: " --log-level 4
    iptables -A INPUT -p udp --dport $port -j SET --add-set blacklist_udp src
    iptables -A INPUT -p udp --dport $port -j SET --add-set blacklist src
    iptables -A INPUT -p udp --dport $port -j DROP
    iptables -A INPUT -p tcp --dport $port -j DROP
done

iptables -A INPUT -p udp --dport 53 -m string --string "ANY" --algo bm -j LOG --log-prefix "DNS_ANY: "
iptables -A INPUT -p udp --dport 53 -m string --string "ANY" --algo bm -j SET --add-set blacklist_udp src
iptables -A INPUT -p udp --dport 53 -m string --string "ANY" --algo bm -j SET --add-set blacklist src
iptables -A INPUT -p udp --dport 53 -m string --string "ANY" --algo bm -j DROP

iptables -A INPUT -p udp --dport 123 -m string --string "monlist" --algo bm -j LOG --log-prefix "NTP_MONLIST: "
iptables -A INPUT -p udp --dport 123 -m string --string "monlist" --algo bm -j SET --add-set blacklist_udp src
iptables -A INPUT -p udp --dport 123 -m string --string "monlist" --algo bm -j SET --add-set blacklist src
iptables -A INPUT -p udp --dport 123 -m string --string "monlist" --algo bm -j DROP

iptables -A INPUT -p udp --dport 1900 -m string --string "M-SEARCH" --algo bm -j LOG --log-prefix "SSDP: "
iptables -A INPUT -p udp --dport 1900 -m string --string "M-SEARCH" --algo bm -j SET --add-set blacklist_udp src
iptables -A INPUT -p udp --dport 1900 -m string --string "M-SEARCH" --algo bm -j SET --add-set blacklist src
iptables -A INPUT -p udp --dport 1900 -m string --string "M-SEARCH" --algo bm -j DROP

iptables -A INPUT -p udp -m hashlimit --hashlimit-name UDP_GLOBAL --hashlimit-mode srcip --hashlimit 60/second --hashlimit-burst 120 -j ACCEPT
iptables -A INPUT -p udp -j LOG --log-prefix "UDP_GLOBAL_BAN: "
iptables -A INPUT -p udp -j SET --add-set blacklist_udp src
iptables -A INPUT -p udp -j SET --add-set blacklist src
iptables -A INPUT -p udp -j DROP

iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j SET --add-set blacklist_tcp src
iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j SET --add-set blacklist src
iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j DROP

iptables -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j SET --add-set blacklist_tcp src
iptables -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j SET --add-set blacklist src
iptables -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j DROP

iptables -A INPUT -p tcp --dport 80 -m limit --limit 5/sec --limit-burst 10 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --set --name slowloris
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 30 --hitcount 10 --name slowloris -j SET --add-set blacklist_tcp src
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 30 --hitcount 10 --name slowloris -j SET --add-set blacklist src
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 30 --hitcount 10 --name slowloris -j DROP

iptables -A INPUT -p tcp --dport 443 -m limit --limit 5/sec --limit-burst 10 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --set --name slowloris443
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 30 --hitcount 10 --name slowloris443 -j SET --add-set blacklist_tcp src
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 30 --hitcount 10 --name slowloris443 -j SET --add-set blacklist src
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 30 --hitcount 10 --name slowloris443 -j DROP

iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m hashlimit --hashlimit-name SLOWLORIS80 --hashlimit-mode srcip --hashlimit 3/minute --hashlimit-burst 5 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j SET --add-set blacklist_tcp src
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j SET --add-set blacklist src
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j DROP

iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -m hashlimit --hashlimit-name SLOWLORIS443 --hashlimit-mode srcip --hashlimit 3/minute --hashlimit-burst 5 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j SET --add-set blacklist_tcp src
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j SET --add-set blacklist src
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j DROP

iptables -A INPUT -p udp -m limit --limit 30/second --limit-burst 60 -j ACCEPT
iptables -A INPUT -p udp -m hashlimit --hashlimit-name UDP_FLOOD --hashlimit-mode srcip --hashlimit 15/second --hashlimit-burst 30 -j ACCEPT
iptables -A INPUT -p udp -j LOG --log-prefix "UDP_BAN: " --log-level 4
iptables -A INPUT -p udp -j SET --add-set blacklist_udp src
iptables -A INPUT -p udp -j SET --add-set blacklist src
iptables -A INPUT -p udp -j DROP

iptables -A INPUT -p udp --dport 53 -m hashlimit --hashlimit-name DNS_LIMIT --hashlimit-mode srcip --hashlimit 30/second --hashlimit-burst 60 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j LOG --log-prefix "DNS_BAN: " --log-level 4
iptables -A INPUT -p udp --dport 53 -j SET --add-set blacklist_udp src
iptables -A INPUT -p udp --dport 53 -j SET --add-set blacklist src
iptables -A INPUT -p udp --dport 53 -j DROP

iptables -A INPUT -p udp --dport 123 -m hashlimit --hashlimit-name NTP_LIMIT --hashlimit-mode srcip --hashlimit 10/second --hashlimit-burst 20 -j ACCEPT
iptables -A INPUT -p udp --dport 123 -j LOG --log-prefix "NTP_BAN: " --log-level 4
iptables -A INPUT -p udp --dport 123 -j SET --add-set blacklist_udp src
iptables -A INPUT -p udp --dport 123 -j SET --add-set blacklist src
iptables -A INPUT -p udp --dport 123 -j DROP

for port in 443 5000 8000 8080 8443 9000; do
    iptables -A INPUT -p udp --dport $port -m hashlimit --hashlimit-name UDP_PORT_$port --hashlimit-mode srcip --hashlimit 5/second --hashlimit-burst 10 -j ACCEPT
    iptables -A INPUT -p udp --dport $port -j LOG --log-prefix "UDP_PORT_BAN: " --log-level 4
    iptables -A INPUT -p udp --dport $port -j SET --add-set blacklist_udp src
    iptables -A INPUT -p udp --dport $port -j SET --add-set blacklist src
    iptables -A INPUT -p udp --dport $port -j DROP
done

iptables -A INPUT -p tcp --syn -m limit --limit 50/second --limit-burst 100 -j ACCEPT
iptables -A INPUT -p tcp --syn -j LOG --log-prefix "SYN_BAN: " --log-level 4
iptables -A INPUT -p tcp --syn -j SET --add-set blacklist_tcp src
iptables -A INPUT -p tcp --syn -j SET --add-set blacklist src
iptables -A INPUT -p tcp --syn -j DROP

iptables -A INPUT -p tcp -m connlimit --connlimit-above 30 --connlimit-mask 32 -j SET --add-set blacklist_tcp src
iptables -A INPUT -p tcp -m connlimit --connlimit-above 30 --connlimit-mask 32 -j SET --add-set blacklist src
iptables -A INPUT -p tcp -m connlimit --connlimit-above 30 --connlimit-mask 32 -j DROP

for p in 22 80 443 8080 8443 2022 5000; do
    iptables -A INPUT -p tcp --dport $p -m conntrack --ctstate NEW -j ACCEPT
done

iptables -A INPUT -j LOG --log-prefix "FINAL_DROP: " --log-level 4

netfilter-persistent save

iptables -N SSH_BRUTE 2>/dev/null || true
iptables -F SSH_BRUTE 2>/dev/null || true
iptables -A SSH_BRUTE -j SET --add-set autoban src
iptables -A SSH_BRUTE -j DROP

iptables -F DOCKER-USER 2>/dev/null || true
iptables -A DOCKER-USER -j RETURN 2>/dev/null || true
iptables -C FORWARD -j DOCKER-USER 2>/dev/null || iptables -A FORWARD -j DOCKER-USER

for net in 0.0.0.0/8 127.0.0.0/8 169.254.0.0/16 224.0.0.0/4 240.0.0.0/5; do
    iptables -A INPUT -s $net -j DROP
done

iptables -A INPUT -p tcp -m connlimit --connlimit-above 60 --connlimit-mask 32 -j SET --add-set autoban src
iptables -A INPUT -p tcp -m connlimit --connlimit-above 60 --connlimit-mask 32 -j DROP

iptables -A INPUT -p tcp --syn -m limit --limit 80/second --limit-burst 160 -j ACCEPT
iptables -A INPUT -p tcp --syn -j SET --add-set autoban src
iptables -A INPUT -p tcp --syn -j DROP

iptables -A INPUT -p udp -m limit --limit 150/second --limit-burst 300 -j ACCEPT
iptables -A INPUT -p udp -m hashlimit --hashlimit-name UDP_FLOOD2 --hashlimit-mode srcip --hashlimit 60/second --hashlimit-burst 120 -j SET --add-set udp_flood src
iptables -A INPUT -p udp -m hashlimit --hashlimit-name UDP_FLOOD2 --hashlimit-mode srcip --hashlimit 60/second --hashlimit-burst 120 -j SET --add-set autoban src
iptables -A INPUT -p udp -j DROP

iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 --connlimit-mask 32 -j SET --add-set tcp_flood src
iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 --connlimit-mask 32 -j SET --add-set autoban src
iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 --connlimit-mask 32 -j DROP

iptables -A INPUT -p tcp -m recent --name portscan --update --seconds 15 --hitcount 100 -j SET --add-set blacklist src
iptables -A INPUT -p tcp -m recent --name portscan --update --seconds 15 --hitcount 100 -j SET --add-set autoban src
iptables -A INPUT -p tcp -m recent --name portscan --set -j ACCEPT

iptables -A INPUT -p tcp --dport 22 -m recent --name ssh_attack --update --seconds 180 --hitcount 4 -j SSH_BRUTE
iptables -A INPUT -p tcp --dport 22 -m recent --name ssh_attack --set -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 3 --connlimit-mask 32 -j SSH_BRUTE
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

for p in 80 443 8080 8443 2022 5000; do
    iptables -A INPUT -p tcp --dport $p -m conntrack --ctstate NEW -j ACCEPT
done

for port in 80 443 8080 8443; do
    iptables -A INPUT -p tcp --dport $port -m connlimit --connlimit-above 60 --connlimit-mask 32 -j SET --add-set autoban src
    iptables -A INPUT -p tcp --dport $port -m connlimit --connlimit-above 60 --connlimit-mask 32 -j DROP
    iptables -A INPUT -p tcp --dport $port -m hashlimit --hashlimit-name HTTP_$port --hashlimit-mode srcip --hashlimit 50/second --hashlimit-burst 100 -j SET --add-set autoban src
    iptables -A INPUT -p tcp --dport $port -m hashlimit --hashlimit-name HTTP_$port --hashlimit-mode srcip --hashlimit 50/second --hashlimit-burst 100 -j DROP
done

for port in 53 123 443 80 8080 8443 5000 8000 9000; do
    iptables -A INPUT -p udp --dport $port -m hashlimit --hashlimit-name UDP_PORT2_$port --hashlimit-mode srcip --hashlimit 50/second --hashlimit-burst 100 -j SET --add-set autoban src
    iptables -A INPUT -p udp --dport $port -m hashlimit --hashlimit-name UDP_PORT2_$port --hashlimit-mode srcip --hashlimit 50/second --hashlimit-burst 100 -j DROP
done

iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m hashlimit \
  --hashlimit-name GLOBAL_CONN \
  --hashlimit-mode srcip \
  --hashlimit-above 50/second \
  --hashlimit-burst 100 \
  -j SET --add-set autoban src

iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m hashlimit \
  --hashlimit-name GLOBAL_CONN \
  --hashlimit-mode srcip \
  --hashlimit-above 50/second \
  --hashlimit-burst 100 \
  -j DROP

iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m hashlimit \
  --hashlimit-name HTTP80 \
  --hashlimit-mode srcip \
  --hashlimit-above 60/second \
  --hashlimit-burst 120 \
  -j SET --add-set autoban src

iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m hashlimit \
  --hashlimit-name HTTP80 \
  --hashlimit-mode srcip \
  --hashlimit-above 60/second \
  --hashlimit-burst 120 \
  -j DROP

iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -m hashlimit \
  --hashlimit-name HTTP443 \
  --hashlimit-mode srcip \
  --hashlimit-above 50/second \
  --hashlimit-burst 100 \
  -j SET --add-set autoban src

iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -m hashlimit \
  --hashlimit-name HTTP443 \
  --hashlimit-mode srcip \
  --hashlimit-above 50/second \
  --hashlimit-burst 100 \
  -j DROP

iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 60 --connlimit-mask 32 -j DROP
iptables -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above 60 --connlimit-mask 32 -j DROP

iptables -A INPUT -p tcp --dport 80 -m limit --limit 20/sec --limit-burst 40 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m limit --limit 20/sec --limit-burst 40 -j ACCEPT

iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --set --name slowloris
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name slowloris -j SET --add-set blacklist_tcp src
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name slowloris -j SET --add-set blacklist src
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name slowloris -j DROP

iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --set --name slowloris443
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name slowloris443 -j SET --add-set blacklist_tcp src
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name slowloris443 -j SET --add-set blacklist src
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name slowloris443 -j DROP

iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j DROP

cat > /etc/nginx/conf.d/http2-rapid-reset.conf << 'EOF'
limit_req_zone $binary_remote_addr zone=http2_limit:10m rate=20r/s;
limit_conn_zone $binary_remote_addr zone=http2_conn:10m;
client_max_body_size 1M;
client_body_buffer_size 128k;
large_client_header_buffers 4 8k;
EOF

NGINX_CONF=$(find /etc/nginx -type f \( -name "*.conf" -o -name "*.vhost" \))

for file in $NGINX_CONF; do
  if grep -q "listen 443" "$file"; then
    sed -i '/http2_max_concurrent_streams/d' "$file"
    sed -i '/limit_req zone=http2_limit/d' "$file"
    sed -i '/limit_conn http2_conn/d' "$file"
    sed -i '/keepalive_timeout/d' "$file"
    sed -i '/client_header_timeout/d' "$file"
    sed -i '/client_body_timeout/d' "$file"
    sed -i '/send_timeout/d' "$file"
    sed -i '/client_max_body_size/d' "$file"
    sed -i '/large_client_header_buffers/d' "$file"

    sed -i '/listen 443/a \
    http2_max_concurrent_streams 32;\n\
    limit_req zone=http2_limit burst=40 nodelay;\n\
    limit_conn http2_conn 20;\n\
    keepalive_timeout 15s;\n\
    client_header_timeout 10s;\n\
    client_body_timeout 10s;\n\
    send_timeout 10s;\n\
    client_max_body_size 1M;\n\
    large_client_header_buffers 4 8k;' "$file"
  fi
done

iptables -C INPUT -p tcp --dport 443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
iptables -I INPUT -p tcp --dport 443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -C INPUT -p tcp --dport 443 -m conntrack --ctstate NEW \
  -m hashlimit --hashlimit-name HTTP2_LIMIT \
  --hashlimit-mode srcip \
  --hashlimit 120/minute \
  --hashlimit-burst 50 \
  -j ACCEPT 2>/dev/null || \
iptables -I INPUT -p tcp --dport 443 -m conntrack --ctstate NEW \
  -m hashlimit --hashlimit-name HTTP2_LIMIT \
  --hashlimit-mode srcip \
  --hashlimit 120/minute \
  --hashlimit-burst 50 \
  -j ACCEPT

iptables -C INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j DROP 2>/dev/null || \
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j DROP

iptables -A INPUT -m state --state NEW -m limit --limit 120/second --limit-burst 240 -j ACCEPT
iptables -A INPUT -m state --state NEW -j DROP

iptables -A INPUT -j LOG --log-prefix "OBLITERATE_BLOCK: " --log-level 4
iptables -A INPUT -j DROP

tc qdisc del dev $INTERFACE root 2>/dev/null || true
tc qdisc add dev $INTERFACE root handle 1: htb default 30
tc class add dev $INTERFACE parent 1: classid 1:1 htb rate 1000mbit
tc class add dev $INTERFACE parent 1:1 classid 1:10 htb rate 100mbit ceil 500mbit
tc class add dev $INTERFACE parent 1:1 classid 1:20 htb rate 50mbit ceil 100mbit
tc class add dev $INTERFACE parent 1:1 classid 1:30 htb rate 10mbit ceil 20mbit
tc qdisc add dev $INTERFACE parent 1:10 handle 10: sfq perturb 10
tc qdisc add dev $INTERFACE parent 1:20 handle 20: sfq perturb 10
tc qdisc add dev $INTERFACE parent 1:30 handle 30: sfq perturb 10

iptables -t mangle -A PREROUTING -p tcp -m connlimit --connlimit-above 60 --connlimit-mask 32 -j CLASSIFY --set-class 1:30
iptables -t mangle -A PREROUTING -p udp -m hashlimit --hashlimit-name udp_bw --hashlimit-mode srcip --hashlimit 50/second --hashlimit-burst 100 -j CLASSIFY --set-class 1:20

systemctl restart docker 2>/dev/null || true
systemctl restart pteroq 2>/dev/null || true
nginx -t && systemctl restart nginx

cat > /etc/nginx/conf.d/fake-headers.conf << 'EOF'
add_header CF-Cache-Status "MISS" always;
add_header CF-RAY "9000000000000000-AMS" always;
add_header X-RateLimit-Limit "100" always;
add_header X-RateLimit-Remaining "0" always;
add_header X-RateLimit-Reset "3600" always;
add_header Retry-After "3600" always;
EOF

nginx -t && systemctl reload nginx

cat <<'HTML_EOF' > 429.php
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>429 - Too Many Requests</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:Arial,sans-serif;}
body{background:#000;height:100vh;display:flex;justify-content:center;align-items:center;text-align:center;color:#fff;}
.box{width:90%;max-width:320px;}
h1{font-size:20px;font-weight:700;margin-bottom:25px;}
button{width:100%;padding:14px;border:none;border-radius:35px;background:linear-gradient(135deg,#2563eb,#3b82f6);color:#fff;font-size:17px;font-weight:600;cursor:pointer;transition:.2s;box-shadow:0 0 20px rgba(59,130,246,.35);}
button i{margin-right:8px;}
button:active{transform:scale(.98);}
</style>
</head>
<body>
<div class="box">
    <h1>Too Many Requests</h1>
    <button onclick="location.reload()"><i class="fa-solid fa-rotate-right"></i>Refresh page</button>
</div>
</body>
</html>
HTML_EOF

cat <<'PHP_EOF' > index.php
<?php
session_start();

$ip = $_SERVER['HTTP_CF_CONNECTING_IP'] ?? $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';

if (strpos($ip, ',') !== false) {
    $ip = explode(',', $ip)[0];
}

if (!filter_var($ip, FILTER_VALIDATE_IP)) {
    $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
}

$ua = trim($_SERVER['HTTP_USER_AGENT'] ?? '');
$uri = $_SERVER['REQUEST_URI'] ?? '';
$path = parse_url($uri, PHP_URL_PATH) ?? '/';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

$whitelistIps = [
    '168.144.129.131',
    '114.10.134.224',
    '68.183.228.145'
];

$whitelistUa = [
    'Wings', 'Go-http-client', 'Docker', 'kube-probe', 'cadvisor',
    'prometheus', 'grafana', 'consul', 'nomad', 'vault', 'traefik',
    'nginx-ingress', 'istio', 'envoy', 'linkerd'
];

$whitelistPaths = [
    '/health', '/healthz', '/ready', '/live', '/metrics', '/ping', '/status'
];

$isApi = strpos($path, '/api/') === 0 || strpos($path, '/api/client/') === 0 || strpos($path, '/api/application/') === 0;
$isWings = stripos($ua, 'Wings') !== false || stripos($ua, 'Go-http-client') !== false || $ip === '127.0.0.1';
$isDocker = stripos($ua, 'Docker') !== false || stripos($ua, 'containerd') !== false;
$isK8s = stripos($ua, 'kube-probe') !== false || stripos($ua, 'cadvisor') !== false;
$isMonitoring = stripos($ua, 'prometheus') !== false || stripos($ua, 'grafana') !== false;
$isWhitelistedIp = in_array($ip, $whitelistIps);
$isWhitelistedUa = in_array($ua, $whitelistUa) || stripos($ua, 'Docker') !== false;
$isWhitelistedPath = in_array($path, $whitelistPaths) || strpos($path, '/.well-known/') === 0;

if ($isApi || $isWings || $isDocker || $isK8s || $isMonitoring || $isWhitelistedIp || $isWhitelistedUa || $isWhitelistedPath || $path === '/favicon.ico') {
    if (file_exists(__DIR__ . '/index.php.bak')) {
        require __DIR__ . '/index.php.bak';
    } else {
        echo "Panel is running normally.";
    }
    exit;
}

if (empty($ua)) {
    http_response_code(403);
    die("🚫 Empty User-Agent blocked.");
}

$badUaKeywords = [
    'curl', 'wget', 'python', 'scrapy', 'sqlmap', 'nikto', 'masscan',
    'zgrab', 'crawler', 'scanner', 'spider', 'bot', 'axios', 'okhttp',
    'libwww', 'perl', 'ruby', 'java/'
];

foreach ($badUaKeywords as $badUa) {
    if (stripos($ua, $badUa) !== false) {
        http_response_code(403);
        die("🚫 Bad User-Agent blocked.");
    }
}

$dailyLimitFile = sys_get_temp_dir() . "/daily_" . md5($ip);
$dailyLimit = 500;

if (!file_exists($dailyLimitFile)) {
    $dailyData = ["count" => 1, "day" => date('Y-m-d')];
    file_put_contents($dailyLimitFile, json_encode($dailyData));
} else {
    $dailyData = json_decode(file_get_contents($dailyLimitFile), true);
    if (!is_array($dailyData)) {
        $dailyData = ["count" => 0, "day" => date('Y-m-d')];
    }
    
    if ($dailyData["day"] !== date('Y-m-d')) {
        $dailyData = ["count" => 1, "day" => date('Y-m-d')];
    } else {
        $dailyData["count"]++;
    }
    file_put_contents($dailyLimitFile, json_encode($dailyData));
}

if ($dailyData["count"] > $dailyLimit && !$isWhitelistedIp && !$isWhitelistedUa && !$isWhitelistedPath) {
    banIpIptables($ip, "Daily limit exceeded: {$dailyData['count']} requests today");
    http_response_code(429);
    die("🚫 Daily request limit exceeded. Try again tomorrow.");
}

$dangerousMethods = ['OPTIONS', 'CONNECT', 'TRACE', 'TRACK'];
if (in_array($method, $dangerousMethods)) {
    banIpIptables($ip, "Dangerous method blocked: $method");
    http_response_code(405);
    die("🚫 Method {$method} is not allowed.");
}

function banIpIptables($ip, $reason) {
    $ipBanLogFile = __DIR__ . '/ip_ban.log';
    
    if (file_exists($ipBanLogFile)) {
        $banned = file($ipBanLogFile, FILE_IGNORE_NEW_LINES);
        foreach ($banned as $line) {
            if (strpos($line, "IP: $ip |") !== false) {
                return true;
            }
        }
    }
    
    exec("ipset create blacklist hash:ip timeout 86400 -exist 2>/dev/null");
    exec("ipset add blacklist $ip -exist 2>/dev/null");
    exec("iptables -I INPUT -m set --match-set blacklist src -j DROP 2>/dev/null");
    
    $logEntry = date('Y-m-d H:i:s') . " | IP: $ip | Reason: $reason\n";
    file_put_contents($ipBanLogFile, $logEntry, FILE_APPEND);
    
    return true;
}

$globalLockFile = sys_get_temp_dir() . "/global_lock";
$lockDuration = 300;

if (file_exists($globalLockFile) && !$isWhitelistedIp && !$isWhitelistedUa && !$isWhitelistedPath) {
    $lockTime = (int)file_get_contents($globalLockFile);

    if (time() - $lockTime < $lockDuration) {
        http_response_code(429);
        header('Retry-After: ' . ($lockDuration - (time() - $lockTime)));

        require __DIR__ . '/429.php';
        exit;
    } else {
        @unlink($globalLockFile);
    }
}

$rateFile = sys_get_temp_dir() . "/rate_" . md5($ip . $method);
$rateWindow = 60;
$maxRequests = 30;

if ($method === 'POST') {
    $maxRequests = 20;
    $rateWindow = 60;
} elseif ($method === 'GET') {
    $maxRequests = 30;
    $rateWindow = 60;
} elseif ($method === 'PUT' || $method === 'DELETE') {
    $maxRequests = 60;
    $rateWindow = 120;
}

if (strpos($path, '/login') !== false || strpos($path, '/auth') !== false) {
    $maxRequests = 20;
    $rateWindow = 300;
}

if (file_exists($rateFile)) {
    $data = json_decode(file_get_contents($rateFile), true);

    if (!is_array($data)) {
        $data = ["count" => 0, "time" => time(), "blocked" => false];
    }
} else {
    $data = ["count" => 0, "time" => time(), "blocked" => false];
}

if ((time() - $data["time"]) > $rateWindow) {
    $data = ["count" => 0, "time" => time(), "blocked" => false];
}

$data["count"]++;

file_put_contents($rateFile, json_encode($data));

if ($data["count"] > $maxRequests && !$isWhitelistedIp && !$isWhitelistedUa && !$isWhitelistedPath) {
    banIpIptables($ip, "Rate limit exceeded: {$data['count']} requests in {$rateWindow} sec");
    file_put_contents($globalLockFile, time());

    $logFile = '/var/log/iptables_ban.log';
    $logData = date('Y-m-d H:i:s') . " | $ip | $method | $path | $ua | BANNED | {$data['count']} requests in {$rateWindow} sec\n";

    file_put_contents($logFile, $logData, FILE_APPEND);

    http_response_code(403);
    die("🚫 Blocked");
}

if (file_exists(__DIR__ . '/index.php.bak')) {
    require __DIR__ . '/index.php.bak';
} else {
    echo "Panel is running normally.";
}

exit;
PHP_EOF

ipset create blacklist hash:ip timeout 86400 -exist 2>/dev/null
iptables -I INPUT -m set --match-set blacklist src -j DROP 2>/dev/null

echo -e "\033[1;45m        FIREWALL INSTALL DONE        \033[0m"
