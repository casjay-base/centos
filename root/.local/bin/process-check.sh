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
# Reopen in a terminal
#if [ ! -t 0 ] && { [ "$1" = --term ] || [ $# = 0 ]; }; then { [ "$1" = --term ] && shift 1 || true; } && TERMINAL_APP="TRUE" myterminal -e "$APPNAME $*" && exit || exit 1; fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initial debugging
[ "$1" = "--debug" ] && set -x && export SCRIPT_OPTS="--debug" && export _DEBUG="on"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Disables colorization
[ "$1" = "--raw" ] && export SHOW_RAW="true"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# pipes fail
set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Send all output to /dev/null
__devnull() {
  tee &>/dev/null && exitCode=0 || exitCode=1
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
# Send errors to /dev/null
__devnull2() {
  [ -n "$1" ] && local cmd="$1" && shift 1 || return 1
  eval $cmd "$*" 2>/dev/null && exitCode=0 || exitCode=1
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
# See if the executable exists
__cmd_exists() {
  exitCode=0
  [ -n "$1" ] && local exitCode="" || return 0
  for cmd in "$@"; do
    builtin command -v "$cmd" &>/dev/null && exitCode+=$(($exitCode + 0)) || exitCode+=$(($exitCode + 1))
  done
  [ $exitCode -eq 0 ] || exitCode=3
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check for a valid internet connection
__am_i_online() {
  local exitCode=0
  curl -q -LSsfI --max-time 1 --retry 0 "${1:-http://1.1.1.1}" 2>&1 | grep -qi 'server:.*cloudflare' || exitCode=4
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# colorization
if [ "$SHOW_RAW" = "true" ]; then
  __printf_color() { printf '%b' "$1\n" | tr -d '\t' | sed '/^%b$/d;s,\x1B\[ 0-9;]*[a-zA-Z],,g'; }
else
  __printf_color() { printf "%b" "$(tput setaf "${2:-7}" 2>/dev/null)" "$1\n" "$(tput sgr0 2>/dev/null)"; }
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# output version
__version() {
  __printf_color "$VERSION" "6"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Help function - Align to 50
__help() {
  __printf_head "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  __printf_opts "process-check: Check and restart failed processes - $VERSION"
  __printf_head "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  __printf_line "Usage: process-check [options] [commands]"
  __printf_line "$PPNAME                         - Check and restart failed processes"
  __printf_head "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  __printf_opts "Other Options"
  __printf_head "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  __printf_line "--help                          - Shows this message"
  __printf_line "--config                        - Generate user config file"
  __printf_line "--version                       - Show script version"
  __printf_line "--options                       - Shows all available options"
  __printf_line "--debug                         - Enables script debugging"
  __printf_line "--raw                           - Removes all formatting on output"
  __printf_head "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User defined functions
__proc_check() {
  proc="$(ps aux 2>&1 | grep -v 'grep' | grep -w "$1" | head -n1 | grep '^' | grep -q "$1" || echo '')"
  [ -n "$proc" ] && printf '%s\n' "$proc" || return 1
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__get_proc_port() {
  port="$(netstat -tapln | grep "$1" | tr ' ' '\n' | grep -v '^$' | grep ':[0-9]' | head -n 1 | sed 's|.*:||g' | head -n1 | grep '^' || echo '' || echo '')"
  [ -n "$port" ] && printf '%s\n' "$port" || return 1
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__server_check() {
  check="$(__get_proc_port "$1")"
  [ -n "$check" ] && curl -q -LSsf "http://localhost:$port" &>/dev/null || return 1
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__service_exists() {
  if systemctl status "$1" >/dev/null 2>&1; then return 0; else return 1; fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__service_restart() {
  if __service_exists "$1" && systemctl restart "$1" >/dev/null 2>&1; then return 0; else return 1; fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User defined variables/import external variables

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check for needed applications
#type -P sh &>/dev/null || exit 3       # exit 3 if not found
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set variables
exitProcCode=0
PROCS="named postfix crond dockerd sshd php-fpm"
SERVE="nginx httpd "
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set additional variables
PROCESS_CHECK_CONFIG_FILE="settings.conf"
PROCESS_CHECK_CONFIG_DIR="$HOME/.config/$APPNAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# bring in user config
[ -f "$PROCESS_CHECK_CONFIG_DIR/$PROCESS_CHECK_CONFIG_FILE" ] &&
  . "$PROCESS_CHECK_CONFIG_DIR/$PROCESS_CHECK_CONFIG_FILE"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Argument/Option settings
SETARGS=("$@")
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SHORTOPTS=""
SHORTOPTS+=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
LONGOPTS="completions:,config,debug,help,options,raw,version"
LONGOPTS+=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ARRAY=""
ARRAY+=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
LIST=""
LIST+=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup application options
setopts=$(getopt -o "$SHORTOPTS" --long "$LONGOPTS" -n "$APPNAME" -- "$@" 2>/dev/null)
eval set -- "${setopts[@]}" 2>/dev/null
while :; do
  case "$1" in
  --raw)
    shift 1
    export SHOW_RAW="true"
    __printf_column() { tee | grep '^'; }
    __printf_color() { printf '%b\n' "$1" | tr -d '\t' | sed '/^%b$/d;s,\x1B\[ 0-9;]*[a-zA-Z],,g'; }
    ;;
  --debug)
    shift 1
    set -xo pipefail
    export SCRIPT_OPTS="--debug"
    export _DEBUG="on"
    __devnull() { tee || return 1; }
    __devnull2() { eval "$@" |& tee || return 1; }
    ;;
  --completions)
    if [ "$2" = "long" ]; then
      printf '%s\n' "--$LONGOPTS" | sed 's|"||g;s|:||g;s|,|,--|g' | tr ',' '\n'
    elif [ "$2" = "short" ]; then
      printf '%s\n' "-$SHORTOPTS" | sed 's|"||g;s|:||g;s|,|,-|g' | tr ',' '\n'
    elif [ "$2" = "array" ]; then
      printf '%s\n' "$ARRAY" | sed 's|"||g;s|:||g' | tr ',' '\n'
    elif [ "$2" = "list" ]; then
      printf '%s\n' "$LIST" | sed 's|"||g;s|:||g' | tr ',' '\n'
    else
      exit 1
    fi
    shift 2
    exit $?
    ;;
  --options)
    shift 1
    __printf_color "Current options for ${PROG:-$APPNAME}" '4'
    [ -z "$SHORTOPTS" ] || __list_options "Short Options" "-${SHORTOPTS}" ',' '-' 4
    [ -z "$LONGOPTS" ] || __list_options "Long Options" "--${LONGOPTS}" ',' '--' 4
    [ -z "$ARRAY" ] || __list_options "Base Options" "${ARRAY}" ',' '' 4
    exit $?
    ;;
  --version)
    shift 1
    __version
    exit $?
    ;;
  --help)
    shift 1
    __help
    exit $?
    ;;
  --config)
    shift 1
    __gen_config
    exit $?
    ;;
  --)
    shift 1
    break
    ;;
  esac
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main application
for proc in $PROCS; do
  if ! __proc_check "$procs"; then
    printf '%s\n' "Attempting to restart $proc"
    __service_restart "$proc" &>/dev/null
    exitProcCode=$((1 + exitProcCode))
  fi
done
for server in $SERVE; do
  if ! __server_check "$server"; then
    printf '%s\n' "Attempting to restart $server"
    systemctl restart "$server" &>/dev/null
    exitProcCode=$((1 + exitProcCode))
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
