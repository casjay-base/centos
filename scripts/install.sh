#!/usr/bin/env bash

VERSION="$(echo $(curl -sSL https://github.com/casjay-base/centos/raw/master/version.txt))"

echo -e "\nThis is version $VERSION"
echo -e "Running the automatic update script\nYour system will restart when done"
echo -e "Press control+c now to cancel update"
sleep 10

echo -e "\nUpdating the system!\nSetting up packages\nThis may take some time!\n"

mkdir -p /etc/casjaysdev/updates/versions
echo "$VERSION" >/etc/casjaysdev/updates/versions/configs.txt
chmod -Rf 664 /etc/casjaysdev/updates/versions/configs.txt

rm -Rf /etc/yum.repos.d/*

curl -sSL https://rpm-devel.sourceforge.io/ZREPO/RHEL/7/casjay.repo -o /etc/yum.repos.d/casjay.repo

yum clean all && yum update -y
yum install -y vnstat  
systemctl enable --now vnstat

yum install -y net-tools wget curl git nail e2fsprogs redhat-lsb neovim wget unzip

rm -Rf /tmp/dotfiles

bash -c "$(curl -LSs https://raw.githubusercontent.com/casjay-dotfiles/minimal/master/install.sh)"

timedatectl set-timezone America/New_York

yum install -y cronie-noanacron
for rpms in $(echo cronie-anacron sendmail sendmail-cf); do rpm -ev --nodeps $rpms; done

rm -Rf /root/anaconda-ks.cfg /var/log/anaconda

rm -Rf /etc/yum.repos.d/*
curl -sSL https://rpm-devel.sourceforge.io/ZREPO/RHEL/7/casjay.repo -o /etc/yum.repos.d/casjay.repo
yum clean all && yum update -y

rm -Rf /boot/*rescue*
grub2-mkconfig -o /boot/grub2/grub.cfg

wget -q https://github.com/pkmgr/centos/raw/master/lists/default.list -O /tmp/rpms-default.txt
wget -q https://github.com/pkmgr/centos/raw/master/lists/apache.list -O /tmp/apache.txt
wget -q https://github.com/pkmgr/centos/raw/master/lists/nginx.list -O /tmp/nginx.txt

yum install -y $(cat /tmp/rpms-default.txt /tmp/apache.txt /tmp/nginx.txt) --skip-broken

rm -Rf /etc/named* /var/named/* /etc/ntp* /etc/cron*/0* /etc/cron*/dailyjobs /var/ftp/uploads /etc/httpd/conf.d/ssl.conf /tmp/configs

git clone -q https://github.com/phpsysinfo/phpsysinfo /var/www/html/sysinfo
git clone -q https://github.com/casjay-base/centos /tmp/configs

find /tmp/configs -type f -iname "*.sh" -exec chmod 755 {} \;
find /tmp/configs -type f -iname "*.pl" -exec chmod 755 {} \;
find /tmp/configs -type f -iname "*.cgi" -exec chmod 755 {} \;
find /tmp/configs -type f -exec sed -i "s#myserverdomainname#$(hostname -f)#g" {} \;
find /tmp/configs -type f -exec sed -i "s#myhostnameshort#$(hostname -s)#g" {} \;
find /tmp/configs -type f -exec sed -i "s#mydomainname#$(hostname -f | awk -F. '{$1="";OFS="." ; print $0}' | sed 's/^.//')#g" {} \;

rm -Rf /tmp/configs/etc/{fail2ban,shorewall,shorewall6}
cp -Rf /tmp/configs/{etc,root,usr,var}* /

mkdir -p /etc/rsync.d /var/log/named && chown -Rf named:named /etc/named* /var/named /var/log/named
chown -Rf apache:apache /var/www /usr/share/httpd

sed -i "s#myserverdomainname#$(echo $HOSTNAME)#g" /etc/sysconfig/network
sed -i "s#mydomain#$(echo $HOSTNAME | awk -F. '{$1="";OFS="." ; print $0}' | sed 's/^.//')#g" /etc/sysconfig/network
domainname $(hostname -f | awk -F. '{$1="";OFS="." ; print $0}' | sed 's/^.//') && echo "kernel.domainname=$(domainname)" >>/etc/sysctl.conf

chmod 644 -Rf /etc/cron.d/* /etc/logrotate.d/*
touch /etc/postfix/mydomains.pcre
postmap /etc/postfix/transport /etc/postfix/canonical /etc/postfix/virtual /etc/postfix/mydomains && newaliases
chattr +i /etc/resolv.conf

for s in $(echo sshd tor munin-node cockpit postfix uptimed php-fpm proftpd rsyslog ntpd snmpd cockpit.socket named); do systemctl enable $s; done
for s in $(echo firewalld auditd kdump iscsid.socket iscsi iscsiuio.socket lvm2-lvmetad.socket lvm2-lvmpolld.socket lvm2-monitor mdmonitor fail2ban shorewall shorewall6 dhcpd dhcpd6 radvd); do systemctl disable $s; done

#enable web server
systemctl enable httpd nginx

echo "" >/etc/yum/pluginconf.d/subscription-manager.conf

rm -Rf /tmp/*.tar /tmp/dotfiles /tmp/configs
/root/bin/changeip.sh >/dev/null 2>&1

mkdir -p /mnt/backups /var/www/html/.well-known /etc/letsencrypt/live
echo "" >>/etc/fstab
#echo "10.0.254.1:/mnt/Volume_1/backups         /mnt/backups                 nfs defaults,rw 0 0" >> /etc/fstab
#echo "10.0.254.1:/var/www/html/.well-known     /var/www/html/.well-known    nfs defaults,rw 0 0" >> /etc/fstab
#echo "10.0.254.1:/etc/letsencrypt              /etc/letsencrypt             nfs defaults,rw 0 0" >> /etc/fstab
#mount -a

#if using letsencrypt certificates
chmod 600 /etc/named/certbot-update.conf
#if [[ -d /etc/letsencrypt/live/$(domainname) ]] || [[ -d /etc/letsencrypt/live/domain ]]; then
#  ln -s /etc/letsencrypt/live/$(domainname) /etc/letsencrypt/live/domain
#  find /etc/postfix /etc/httpd /etc/nginx -type f -exec sed -i 's#/etc/ssl/CA/CasjaysDev/certs/ca.crt#/etc/letsencrypt/live/domain/cert.pem#g' {} \;
#  find /etc/postfix /etc/httpd /etc/nginx -type f -exec sed -i 's#/etc/ssl/CA/CasjaysDev/certs/localhost.crt#/etc/letsencrypt/live/domain/fullchain.pem#g' {} \;
#  find /etc/postfix /etc/httpd /etc/nginx -type f -exec sed -i 's#/etc/ssl/CA/CasjaysDev/private/localhost.key#/etc/letsencrypt/live/domain/privkey.pem#g' {} \;
cat /etc/letsencrypt/live/domain/fullchain.pem >/etc/cockpit/ws-certs.d/1-my-cert.cert
cat /etc/letsencrypt/live/domain/privkey.pem >>/etc/cockpit/ws-certs.d/1-my-cert.cert
#else
#If using self-signed certificates
#  find /etc/postfix /etc/httpd /etc/cockpit/ws-certs.d -type f -exec sed -i 's#/etc/letsencrypt/live/domain/cert.pem#/etc/ssl/CA/CasjaysDev/certs/ca.crt#g' {} \;
#  find /etc/postfix /etc/httpd /etc/cockpit/ws-certs.d -type f -exec sed -i 's#/etc/letsencrypt/live/domain/fullchain.pem#/etc/ssl/CA/CasjaysDev/certs/localhost.crt#g' {} \;
#  find /etc/postfix /etc/httpd /etc/cockpit/ws-certs.d -type f -exec sed -i 's#/etc/letsencrypt/live/domain/privkey.pem#/etc/ssl/CA/CasjaysDev/private/localhost.key#g' {} \;
#fi

update-ca-trust && update-ca-trust extract

systemctl start nginx httpd

munin-node-configure --remove-also --shell | sh

if [ -f /var/lib/tor/hidden_service/hostname ]; then cp -Rfv /var/lib/tor/hidden_service/hostname /var/www/html/tor_hostname; fi

chown -Rf apache:apache /var/www
systemctl restart munin-node
history -c && history -w

#systemctl reboot
