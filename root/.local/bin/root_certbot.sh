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
__certbot_api_check() { [ -z "$CERTBOT_API_KEY" ] && return 0 || return 1; }
__certbot_renew() { eval $CERTBOT_BIN renew --agree-tos --expand --dns-rfc2136 --dns-rfc2136-credentials "$CERTBOT_FILE"; }
__certbot_test() { eval $CERTBOT_BIN renew --dry-run --agree-tos --expand --dns-rfc2136 --dns-rfc2136-credentials "$CERTBOT_FILE" || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__certbot_new() {
  certbot certonly -n --agree-tos -m "casjay+ssl@gmail.com" --expand --dns-rfc2136 --dns-rfc2136-credentials /etc/named/certbot-update.conf -key-path "$SSL_KEY" -fullchain-path "$SSL_CERT" "$@" || return 1
  [ -d "$SSL_DIR/$1" ] && [ ! -d "$SSL_DIR/domain" ] && ln -sf "$SSL_DIR/$1" "$SSL_DIR/domain"
  [ -d "" ] || return 1
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CERTBOT_BIN="$(builtin type -P certbot 2>/dev/null || echo '')"
CERTBOT3_BIN="$(builtin type -P certbot-3 2>/dev/null || builtin type -P certbot3 2>/dev/null || echo '')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -f "/etc/named/certbot-update.conf" ]; then
  CERTBOT_FILE="/etc/named/certbot-update.conf"
elif [ -f "/etc/certbot/dns.conf" ]; then
  CERTBOT_FILE="/etc/certbot/dns.conf"
fi
SSL_DIR="/etc/letsencrypt/live"
SSL_KEY="/etc/letsencrypt/live/domain/privkey.pem"
SSL_CERT="/etc/letsencrypt/live/domain/fullchain.pem"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CERTBOT_FILE="${CERTBOT_FILE:-}"
CERTBOT_KEY_FILE="${CERTBOT_KEY_FILE:-/root/.config/certbot/dns_rfc2136_secret}"
CERTBOT_KEY_ENV="${CERTBOT_KEY_ENV:-$(grep -s 'dns_rfc2136_secret = ' "$CERTBOT_FILE" 2>/dev/null | awk -F' = ' '{print $2}' | grep '^' || false)}"
CERTBOT_API_KEY="${CERTBOT_API_KEY:-${CERTBOT_KEY_FILE:-$CERTBOT_KEY_ENV}}"
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
if [ -f "$CERTBOT_KEY_FILE" ]; then
  . "$CERTBOT_KEY_FILE"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -n "$CERTBOT_KEY_ENV" ]; then
  sed -i 's|dns_rfc2136_secret.*|dns_rfc2136_secret = '$CERTBOT_API_KEY'|g' "$CERTBOT_FILE"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -n "$CERTBOT_API_KEY" ]; then
  mkdir -p "/root/.config/certbot"
  echo "CERTBOT_API_KEY=$CERTBOT_KEY_ENV" >"$CERTBOT_KEY_FILE"
  chmod 600 "$CERTBOT_KEY_FILE"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -f "$HOME/dns/certbot.sh" ]; then
  eval "$HOME/dns/certbot.sh" --renew
  exit $?
elif __certbot_api_check; then
  echo "CERTBOT_API_KEY is unset" 1>&2
  exit 1
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
case "$1" in
new | create)
  shift 1
  for domain in "$@"; do DOMAIN="-d $domain "; done
  __certbot_new "$domain"
  exit $?
  ;;
*)
  if [ -n "$CERTBOT_API_KEY" ]; then
    __certbot_test && __certbot_renew
  fi
  ;;
esac
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $?
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
