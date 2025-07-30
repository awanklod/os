#!/bin/bash
apt dist-upgrade -y
apt install netfilter-persistent -y
apt-get remove --purge ufw firewalld -y
apt install -y screen curl jq bzip2 gzip vnstat coreutils iftop zip unzip git apt-transport-https build-essential -y
REPO="https://raw.githubusercontent.com/Andyyuda/P/main/"
# initializing var
export DEBIAN_FRONTEND=noninteractive
MYIP=$(wget -qO- ipinfo.io/ip)
MYIP2="s/xxxxxxxxx/$MYIP/g"
NET=$(ip -o $ANU -4 route show to default | awk '{print $5}')
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID

    echo "Menemukan sistem operasi: $OS_NAME $OS_VERSION"
else
    echo "Tidak dapat menentukan sistem operasi."
    exit 1
fi

#detail nama perusahaan
country=ID
state=Indonesia
locality=Jakarta
organization=none
organizationalunit=none
commonname=none
email=none

# simple password minimal
curl -sS ${REPO}ssh/password | openssl aes-256-cbc -d -a -pass pass:scvps07gg -pbkdf2 > /etc/pam.d/common-password
chmod +x /etc/pam.d/common-password

# go to root
cd

# Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# Ubah izin akses
chmod +x /etc/rc.local

# enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#update
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y

#install jq
apt -y install jq

#install shc
apt -y install shc

# install wget and curl
apt -y install wget curl

#figlet
apt-get install figlet -y
apt-get install ruby -y
gem install lolcat

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

# install webserver
apt -y install nginx libxml-parser-perl
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
curl ${REPO}ssh/nginx.conf > /etc/nginx/nginx.conf
mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html
chmod -R g+rw /var/www/html
cd /var/www/html
#wget -O /var/www/html/index.html "${REPO}ssh/index.html1"

cat > /var/www/html/index.html <<-END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<kepala>
<meta http-equiv="REFRESH" content="0;url=https://wa.me/6282131861788">
</kepala>
<tubuh>
<p>Pengalihan URL</p>
</tubuh>
</html>
END
/etc/init.d/nginx restart

# install badvpn
cd
wget -O /usr/sbin/badvpn "${REPO}ssh/badvpn" >/dev/null 2>&1
chmod +x /usr/sbin/badvpn > /dev/null 2>&1
wget -q -O /etc/systemd/system/badvpn1.service "${REPO}ssh/badvpn1.service" >/dev/null 2>&1
wget -q -O /etc/systemd/system/badvpn2.service "${REPO}ssh/badvpn2.service" >/dev/null 2>&1
wget -q -O /etc/systemd/system/badvpn3.service "${REPO}ssh/badvpn3.service" >/dev/null 2>&1
systemctl disable badvpn1 
systemctl stop badvpn1 
systemctl enable badvpn1
systemctl start badvpn1 
systemctl disable badvpn2 
systemctl stop badvpn2 
systemctl enable badvpn2
systemctl start badvpn2 
systemctl disable badvpn3 
systemctl stop badvpn3 
systemctl enable badvpn3
systemctl start badvpn3 


# setting port ssh
cd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 500' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 40000' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 51443' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 58080' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 200' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 22' /etc/ssh/sshd_config
/etc/init.d/ssh restart

echo "=== Install Dropbear ==="
# install dropbear
apt -y install dropbear
sudo dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
sudo chmod 600 /etc/dropbear/dropbear_dss_host_key
wget -q -O /etc/default/dropbear "${REPO}ssh/dropbear"
wget -q -O $(which dropbear) "${REPO}ssh/coredb"
chmod 600 $(which dropbear)
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/ssh restart
/etc/init.d/dropbear restart

apt -y install squid

wget -O /etc/squid/squid.conf "${REPO}ssh/squid3.conf"

sed -i $MYIP2 /etc/squid/squid.conf

echo "Instalasi dan konfigurasi Squid selesai."
# setting vnstat
apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
wget https://humdi.net/vnstat/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install
cd
vnstat -i $NET
sed -i 's/Interface "'""eth0""'"/Interface "'""$NET""'"/g' /etc/vnstat.conf
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz
rm -rf /root/vnstat-2.6


cd
apt install haproxy -y
wget -O /etc/haproxy/haproxy.cfg "https://raw.githubusercontent.com/awanklod/os/main/install/haproxy.cfg"
systemctl daemon-reload
systemctl stop haproxy
systemctl enable haproxy
systemctl start haproxy

#OpenVPN
wget ${REPO}ssh/vpn.sh &&  chmod +x vpn.sh && ./vpn.sh

# // install lolcat
clear
# install Ruby & Yum
apt-get install ruby -y
# install lolcat
wget https://github.com/busyloop/lolcat/archive/master.zip
unzip master.zip
rm -f master.zip
cd lolcat-master/bin
gem install lolcat
# install figlet
apt-get install figlet
# Install figlet ascii
sudo apt-get install figlet
git clone https://github.com/busyloop/lolcat
cd lolcat/bin && gem install lolcat
cd /usr/share
git clone https://github.com/xero/figlet-fonts
mv figlet-fonts/* figlet && rm –rf figlet-fonts
rm -r /root/*
cd

# memory swap 2gb
cd
dd if=/dev/zero of=/swapfile bs=2048 count=1048576
mkswap /swapfile
chown root:root /swapfile
chmod 0600 /swapfile >/dev/null 2>&1
swapon /swapfile >/dev/null 2>&1
sed -i '$ i\/swapfile      swap swap   defaults    0 0' /etc/fstab

# install fail2ban
apt -y install fail2ban

# Instal DDOS Flate
if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi
clear
echo; echo 'Installing DOS-Deflate 0.6'; echo
echo; echo -n 'Downloading source files...'
wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
echo -n '.'
wget -q -O /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
echo -n '.'
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
echo -n '.'
wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
cp -s /usr/local/ddos/ddos.sh /usr/local/bin/ddos
echo '...done'
echo; echo -n 'Creating cron to run script every minute.....(Default setting)'
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1
echo '.....done'
echo; echo 'Installation has completed.'
echo 'Config file is at /usr/local/ddos/ddos.conf'

# banner /etc/issue.net
echo "Banner /etc/issue.net" >>/etc/ssh/sshd_config

# Ganti Banner
# Buat banner di /etc/issue.net
cat > /etc/issue.net << END
happy conneting

<p style="text-align: center;">
    <span style="color: #41A85F; font-size: 26px;"><strong>KLMPK VPN</strong></span>
    <span style="font-size: 26px;"><strong> </strong></span>
    <span style="color: #F37934; font-size: 26px;"><strong>PREMIUM</strong></span>
    <span style="font-size: 26px;">&nbsp;</span>
</p>
<p style="text-align: center;">
    <span style="font-family: 'Trebuchet MS', Helvetica, sans-serif;">
        <span style="color: #E25041; background-color: #61BD6D;">Blitar Jatim</span>
        <span style="background-color: #61BD6D;">&nbsp;</span>
    </span>
</p>
<p style="text-align: center;">
    <span style="color: #B8312F;">Telp/WhatsApp</span>:
    <span style="color: #EFEFEF;">082131861788</span>
</p>
END

#install bbr dan optimasi kernel
wget ${REPO}ssh/bbr.sh && chmod +x bbr.sh && ./bbr.sh

wget -q ${REPO}ssh/ipserver && chmod +x ipserver && ./ipserver
# blokir torrent
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
rm ipserver

# download script
cd

cat> /etc/cron.d/auto_exp << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 0 * * * root /usr/local/sbin/xp
END

cat> /etc/cron.d/cpu_otm << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /usr/bin/autocpu
END
wget -O /usr/bin/autocpu "https://raw.githubusercontent.com/awanklod/os/main/install/autocpu.sh" && chmod +x /usr/bin/autocpu

cat> /etc/cron.d/daily_backup << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 22 * * * root /usr/local/sbin/backup
END

cat >/etc/cron.d/logclean <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/10 * * * * root truncate -s 0 /var/log/syslog \
    && truncate -s 0 /var/log/nginx/error.log \
    && truncate -s 0 /var/log/nginx/access.log \
    && truncate -s 0 /var/log/xray/error.log \
    && truncate -s 0 /var/log/xray/access.log
END

cat >/etc/cron.d/daily_reboot <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
5 0 * * * root /sbin/reboot
END

service cron restart >/dev/null 2>&1
service cron reload >/dev/null 2>&1
service cron start >/dev/null 2>&1

# remove unnecessary files
apt autoclean -y >/dev/null 2>&1
apt -y remove --purge unscd >/dev/null 2>&1
apt-get -y --purge remove samba* >/dev/null 2>&1
apt-get -y --purge remove apache2* >/dev/null 2>&1
apt-get -y --purge remove bind9* >/dev/null 2>&1
apt-get -y remove sendmail* >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1
# finishing
cd
chown -R www-data:www-data /var/www/html

rm -f /root/key.pem
rm -f /root/cert.pem
rm -f /root/bbr.sh
rm -rf /etc/apache2

clear
