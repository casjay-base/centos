#!/bin/sh
if [ ! -f /usr/sbin/ifconfig ]; then
  printf "The net-tools package is not installed and therefore I can not continue!\n"
  printf "It can be installed with the command yum install -y net-tools\n"
  exit 1
fi

mkdir -p /var/lib/system-scripts/checkip /etc/casjaysdev
#DOMAIN
OLDDOM="myserverdomainname"
NEWDOM="$(hostname -f)"
#ShortHostname
OLDSHORT="myhostnameshort"
NEWSHORT="$(hostname -s)"
#IP4
OLDIP4="10.0.20.1"
NEWIP4="$(/sbin/ifconfig | grep -E "venet|inet" | grep -v "127.0.0." | grep 'inet' | grep -v inet6 | awk '{print $2}' | sed 's|addr:||g' | head -n1)"
#IP6
OLDIP6="2001:db8:edfa:1234:5678::e1a2"
NEWIP6="$(/sbin/ifconfig | grep -E "venet|inet" | grep 'inet6' | grep -i global | awk '{print $2}' | head -n1)"
#
#IPV4
/sbin/ifconfig | grep -E "venet | inet" | grep -v "127.0.0." | grep 'inet' | grep -v inet6 | awk '{print $2}' | sed 's|addr:||g' | head -n1 >/var/lib/system-scripts/checkip/myip4.txt
if [ -z "$NEWIP4" ]; then
  echo no ipv4
else
  echo ipv4 works so continuing with IPV4 changes
  [ -e "/root/.local/bin" ] && find /root/.local/bin -type f -exec sed -i "s#$OLDIP4 #$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/hosts" ] && find /etc/hosts* -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/issue" ] && find /etc/issue* -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/proftpd.conf" ] && find /etc/proftpd* -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/sysconfig/network-scripts" ] && find /etc/sysconfig/network-scripts/ifcfg-eth0 -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/httpd" ] && find /etc/httpd -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/nginx" ] && find /etc/nginx -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/postfix" ] && find /etc/postfix -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/motd" ] && find /etc/motd* -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/named" ] && find /etc/named -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/var/www" ] && find /var/www -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/var/named" ] && find /var/named -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/webmin" ] && find /etc/webmin -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/usermin" ] && find /etc/usermin -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/var/lib/system-scripts" ] && find /var/lib/system-scripts -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
  [ -e "/etc/casjaysdev/system-scripts" ] && find /etc/casjaysdev/system-scripts -type f -exec sed -i "s#$OLDIP4#$NEWIP4#g" {} \; &>/var/log/changeip
fi
#IPV6
/sbin/ifconfig | grep -E "venet|inet" | grep 'inet6' | grep -i global | awk '{print $2}' | head -n1 >/var/lib/system-scripts/checkip/myip6.txt
if [ -z "$NEWIP6" ]; then
  echo no ipv6
  [ -e "/etc/httpd" ] && find /etc/httpd/conf* -type f -exec sed -i "s#\[2001:db8:edfa:1234:5678::e1a2\]:443##g" {} \; &>/var/log/changeip
  [ -e "/etc/nginx" ] && find /etc/httpd/conf* -type f -exec sed -i "s#\[2001:db8:edfa:1234:5678::e1a2\]:443##g" {} \; &>/var/log/changeip
else
  echo ipv6 works so continuing with IPV6 changes
  [ -e "/root/.local/bin" ] && find /root/.local/bin -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/sysconfig/network-scripts" ] && find /etc/sysconfig/network-scripts/ifcfg-* -type f -exec sed -i "s#$OLDIP4#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/etc/postfix" ] && find /etc/postfix -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/etc/httpd" ] && find /etc/httpd -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/etc/nginx" ] && find /etc/nginx -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/etc/proftpd.conf" ] && find /etc/proftpd* -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/etc/named" ] && find /etc/named -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/var/named" ] && find /var/named -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/var/www" ] && find /var/www -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; >/dev/null 2>&1
  [ -e "/etc/hosts" ] && find /etc/hosts* -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/etc/issue" ] && find /etc/issue* -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/etc/motd" ] && find /etc/motd* -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/etc/webmin" ] && find /etc/webmin -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/etc/casjaysdev" ] && find /etc/casjaysdev -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
  [ -e "/system-scripts" ] && find /var/lib/system-scripts -type f -exec sed -i "s#$OLDIP6#$NEWIP6#g" {} \; &>/var/log/changeip
fi
#Domain
[ -e "/root/.local/bin" ] && find /root/.local/bin -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/postfix" ] && find /etc/postfix -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/httpd" ] && find /etc/httpd -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/nginx" ] && find /etc/nginx -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/proftpd.conf" ] && find /etc/proftpd* -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/named" ] && find /etc/named -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/var/named" ] && find /var/named -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/var/www" ] && find /var/www -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; >/dev/null 2>&1
[ -e "/etc/hosts" ] && find /etc/hosts* -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/issue" ] && find /etc/issue* -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/motd" ] && find /etc/motd* -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/munin" ] && find /etc/munin -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/rc.d/rc.local" ] && find /etc/rc.d/rc.local -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/cron.d" ] && find /etc/cron* -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/casjaysdev" ] && find /etc/casjaysdev -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/webmin" ] && find /etc/webmin -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/webalizer" ] && find /etc/webalizer* -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/etc/uptimed.conf" ] && find /etc/uptimed.conf -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
[ -e "/var/lib/system-scripts" ] && find /var/lib/system-scripts -type f -exec sed -i "s#$OLDDOM#$NEWDOM#g" {} \; &>/var/log/changeip
#Change Short HostName
[ -e "/root/.local/bin" ] && find /root/.local/bin -type f -exec sed -i "s#$OLDSHORT#$NEWSHORT#g" {} \; &>/var/log/changeip
[ -e "/etc/casjaysdev" ] && find /etc/casjaysdev -type f -exec sed -i "s#$OLDSHORT#$NEWSHORT#g" {} \; &>/var/log/changeip
[ -e "/etc/httpd" ] && find /etc/httpd -type f -exec sed -i "s#$OLDSHORT#$NEWSHORT#g" {} \; &>/var/log/changeip
[ -e "/etc/nginx" ] && find /etc/nginx -type f -exec sed -i "s#$OLDSHORT#$NEWSHORT#g" {} \; &>/var/log/changeip
if [ ! -z "$NEWIP4" ]; then echo "Changed the IP4 from $OLDIP4 to $NEWIP4"; fi
if [ ! -z "$NEWIP6" ]; then echo "Changed the IP6 from $OLDIP6 to $NEWIP6"; fi
echo "Changed the DOMAIN from $OLDDOM to $NEWDOM"
echo "Changed the HOSTNAME from $OLDSHORT to $NEWSHORT"
