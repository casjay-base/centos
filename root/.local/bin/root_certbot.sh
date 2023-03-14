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
CERTBOT_BIN="$(builtin type -P certbot 2>/dev/null || echo '')"
CERTBOT3_BIN="$(builtin type -P certbot-3 2>/dev/null || builtin type -P certbot3 2>/dev/null || echo '')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CERTBOT_API_KEY="${CERTBOT_API_KEY:-}"
CERTBOT_FILE="${CERTBOT_FILE:-/etc/named/certbot-update.conf}"
CERTBOT_KEY_FILE="${CERTBOT_KEY_FILE:-/root/.config/certbot/dns_rfc2136_secret}"
CERTBOT_KEY_ENV="${CERTBOT_KEY_ENV:-$(grep -s 'dns_rfc2136_secret = ' "/etc/named/certbot-update.conf" 2>/dev/null | awk -F' = ' '{print $2}' | grep '^' || false)}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -z "${CERTBOT3_BIN:-$CERTBOT_BIN}" ]; then
  echo "certbot does not seem to be installed" >&2
  exit 1
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -n "$CERTBOT3_BIN" ] && [ -z "$CERTBOT_BIN" ]; then
  CERTBOT_BIN="$CERTBOT3_BIN"
  ln -sf "$CERTBOT3_BIN" "/usr/bin/certbot"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "$CERTBOT_KEY_FILE" ] && . "$CERTBOT_KEY_FILE"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -f "$HOME/dns/certbot.sh" ]; then
  eval "$HOME/dns/certbot.sh" --renew
elif [ -f "/etc/named/certbot-update.conf" ]; then
  if [ -z "$CERTBOT_API_KEY" ] && [ -n "$CERTBOT_KEY_ENV" ]; then
    mkdir -p "/root/.config/certbot"
    echo "CERTBOT_API_KEY=$CERTBOT_KEY_ENV" >"$CERTBOT_KEY_FILE"
    chmod 600 "$CERTBOT_KEY_FILE"
  fi

  if [ -n "$CERTBOT_KEY_ENV" ]; then
    sed -i 's|dns_rfc2136_secret.*|dns_rfc2136_secret = '$CERTBOT_API_KEY'|g' "$CERTBOT_FILE"
  fi

  if [ -n "$CERTBOT_API_KEY" ] || [ -n "$CERTBOT_KEY_ENV" ]; then
    eval $CERTBOT_BIN renew --dry-run --agree-tos --expand --dns-rfc2136 --dns-rfc2136-credentials "$CERTBOT_FILE" &&
      eval $CERTBOT_BIN renew --agree-tos --expand --dns-rfc2136 --dns-rfc2136-credentials "/etc/named/certbot-update.conf"
  else
    echo "CERTBOT_API_KEY is unset" 1>&2
  fi
else
  eval $CERTBOT_BIN renew -a webroot -w "/var/www/html"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $?
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
