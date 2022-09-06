#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202209061546-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.com
# @@License          :  LICENSE.md
# @@ReadME           :  root_certbot.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Tuesday, Sep 06, 2022 16:15 EDT
# @@File             :  root_certbot.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  shell/sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
certbot="$(command -v certbot 2>/dev/null || echo '')"
certbot3="$(command -v certbot-3 2>/dev/null || echo '')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -f "$certbot3" ] && [ ! -f "$certbot" ]; then
  ln -sf "$certbot3" "$certbot"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "$certbot" ] || exit 1
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -f "$HOME/dns/certbot.sh" ]; then
  "$HOME/dns/certbot.sh" --renew &>>/var/log/le-renew.log
elif [ -f "/etc/named/certbot-update.conf" ]; then
  eval $certbot renew --dry-run --agree-tos --expand --dns-rfc2136 --dns-rfc2136-credentials /etc/named/certbot-update.conf &>>/var/log/le-renew.log &&
    eval $certbot renew --agree-tos --expand --dns-rfc2136 --dns-rfc2136-credentials /etc/named/certbot-update.conf &>>/var/log/le-renew.log
else
  eval $certbot renew -a webroot -w /var/www/html &>>/var/log/le-renew.log
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $?
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
