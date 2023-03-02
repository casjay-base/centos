#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202302281441-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.com
# @@License          :  LICENSE.md
# @@ReadME           :  process-check --help
# @@Copyright        :  Copyright: (c) 2023 Jason Hempstead, Casjays Developments
# @@Created          :  Tuesday, Feb 28, 2023 14:45 EST
# @@File             :  process-check
# @@Description      :  Check and restart failed processes
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  shell/sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="$(basename "$0" 2>/dev/null)"
VERSION="202302281441-git"
HOME="${USER_HOME:-$HOME}"
USER="${SUDO_USER:-$USER}"
RUN_USER="${SUDO_USER:-$USER}"
SCRIPT_SRC_DIR="${BASH_SOURCE%/*}"
FULL_HOSTNAME="$(hostname -f || echo "$HOSTNAME")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initial debugging
[ "$1" = "--debug" ] && set -x && export SCRIPT_OPTS="--debug" && export _DEBUG="on"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# pipes fail
set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set process check
PROCS="named postfix crond dockerd sshd php-fpm "
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User defined functions
__check_url() { curl -q -SsI "$1" &>/dev/null || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__proc_check() {
  proc="$(ps aux 2>&1 | grep -v 'grep' | grep -w "$1" | head -n1 | grep -q "$1" && echo "$1" || echo '')"
  [ -n "$proc" ] || {
    printf '%s\n' "Attempting to restart $1"
    return 1
  }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__get_proc_port() {
  port="$(netstat -tapln | grep "$1" | tr ' ' '\n' | grep -v '^$' | grep ':[0-9]' | head -n 1 | sed 's|.*:||g' | head -n1 | grep '[0-9]' || echo '' || echo '')"
  [ -n "$port" ] && printf '%s\n' "$port" || return 1
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__website_check() {
  check="$(__get_proc_port "$1")"
  url="${2:-}"
  [ -n "$url" ] && [ -n "$check" ] && printf '%s\n' "Checking $url" && __check_url "$url" || {
    printf '%s\n' "Failed to connect to $url"
    return 1
  }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__service_restart() {
  exitcode=0
  if systemctl status "$1" 2>&1 | grep -q "$1.*could not"; then
    exitcode=0
  elif systemctl status "$1" 2>&1 | grep 'Loaded: ' | grep -qwi 'enabled'; then
    if systemctl restart "$1" >/dev/null 2>&1; then
      exitcode=0
    else
      exitcode=1
    fi
  else
    exitcode=0
  fi
  return $exitcode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set exitCode variables
exitProcCode=0
exithttpdCode=0
exitnginxCode=0
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# get apache domains and port
if [ -d "/etc/httpd" ] && __proc_check "httpd"; then
  set_httpd_proto="http"
  get_httpd_domains="$(grep --no-filename -R 'ServerName ' /etc/httpd | grep -Ev '#|localhost' | sed 's|.* ||g;s|;||g;s|server_name ||g' | grep -v '\*' | grep '[a-z0-9]' | sort -u | grep '^' || echo '')"
  get_httpd_port="$(grep -R --no-filename 'Listen ' /etc/httpd/conf/httpd.conf | grep -v '#' | awk -F ' ' '{print $2}' | sort -u | head -n1 | grep '^' || echo '')"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# get nginx domains and port
if [ -d "/etc/nginx" ] && __proc_check "nginx"; then
  set_nginx_proto="https"
  get_nginx_domains="$(grep -R --no-filename 'server_name ' /etc/nginx | grep -Ev '#|localhost' | sed 's|.* ||g;s|;||g;s|server_name ||g' | grep -v '\*' | grep '[a-z0-9]' | sort -u | grep '^' || echo '')"
  get_nginx_port="$(grep -R --no-filename 'listen ' /etc/nginx | grep ' [0-9][0-9]' | awk -F ' ' '{print $2}' | sort -u | head -n1 | grep '^' || echo '')"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# check and restart broken processes
for proc in $PROCS; do
  if [ -n "$proc" ]; then
    if ! __proc_check "$proc"; then
      __service_restart "$proc" &>/dev/null
      exitProcCode=$((1 + exitProcCode))
    fi
  fi
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# check apache hosts by default mine are http
for httpd_site in $get_httpd_domains; do
  if [ -n "$httpd" ]; then
    url="${set_httpd_proto:-http}://$httpd_site:$get_httpd_port"
    if ! __website_check "httpd" "$url"; then
      exithttpdCode=$((1 + exitProcCode))
    fi
  fi
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# check nginx hosts by default mine are http
for nginx_site in $get_nginx_domains; do
  if [ -n "$server" ]; then
    url="${set_nginx_proto:-https}://$nginx_site:$get_nginx_port"
    if ! __server_check "nginx" "$url"; then
      exitnginxCode=$((1 + exitProcCode))
    fi
  fi
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
[ $exithttpdCode -eq 0 ] || __service_restart "httpd"
[ $exitnginxCode -eq 0 ] || __service_restart "nginx"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exitCode=$exitProcCode
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# ex: ts=2 sw=2 et filetype=sh
