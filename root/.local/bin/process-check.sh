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
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initial debugging
[ "$1" = "--debug" ] && set -x && export SCRIPT_OPTS="--debug" && export _DEBUG="on"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# pipes fail
set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User defined functions
__get_proc_port() {
  port="$(netstat -tapln | grep "$1" | tr ' ' '\n' | grep -v '^$' | grep ':[0-9]' | head -n 1 | sed 's|.*:||g' | head -n1 | grep '[0-9]' || echo '' || echo '')"
  [ -n "$port" ] && printf '%s\n' "$port" || return 1
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__server_check() {
  check="$(__get_proc_port "$1")"
  url="http://localhost:$check"
  [ -n "$check" ] && curl -q -SsI "$url" &>/dev/null || {
    printf '%s: %s\n' "Failed to connect to $url" "Attempting to restart $1"
    return 1
  }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__proc_check() {
  proc="$(ps aux 2>&1 | grep -v 'grep' | grep -w "$1" | head -n1 | grep -q "$1" && echo "$1" || echo '')"
  [ -n "$proc" ] || {
    printf '%s\n' "Attempting to restart $1"
    return 1
  }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__service_exists() {
  systemctl status "$1" 2>&1 | grep -q "$1.*could not" && return 0
  systemctl status "$1" 2>&1 | grep 'Active:' | grep -wq 'active' || return 0
  if systemctl status "$1" &>/dev/null; then return 0; else return 1; fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__service_restart() {
  if __service_exists "$1" && systemctl restart "$1" >/dev/null 2>&1; then return 0; else return 1; fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set variables
exitProcCode=0
PROCS="named postfix crond dockerd sshd php-fpm "
SERVE="nginx httpd "
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main application
for proc in $PROCS; do
  if [ -n "$proc" ]; then
    if ! __proc_check "$proc"; then
      __service_restart "$proc" &>/dev/null
      exitProcCode=$((1 + exitProcCode))
    fi
  fi
done
for server in $SERVE; do
  if [ -n "$server" ]; then
    if ! __server_check "$server"; then
      systemctl restart "$server" &>/dev/null
      exitProcCode=$((1 + exitProcCode))
    fi
  fi
done
exitCode=$exitProcCode
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# ex: ts=2 sw=2 et filetype=sh
