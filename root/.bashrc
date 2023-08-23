# $HOME/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

if [ -z "$BASHRCSOURCED" ] && [ -f "/etc/bashrc" ]; then
  . /etc/bashrc && export BASHRCSOURCED="Y"
fi

# Reset variables
unset PROMPT_COMMAND PS1 PS2 PS4 PATH

# export path
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/share/games:/usr/local/sbin:/usr/sbin:/sbin"

# colorize
RESET="$(tput sgr0 2>/dev/null)"
BLACK="$(printf '%b' "\033[0;30m")"
RED="$(printf '%b' "\033[1;31m")"
GREEN="$(printf '%b' "\033[0;32m")"
YELLOW="$(printf '%b' "\033[0;33m")"
BLUE="$(printf '%b' "\033[0;34m")"
PURPLE="$(printf '%b' "\033[0;35m")"
CYAN="$(printf '%b' "\033[0;36m")"
WHITE="$(printf '%b' "\033[0;37m")"
ORANGE="$(printf '%b' "\033[0;33m")"
LIGHTRED="$(printf '%b' '\033[1;31m')"
BG_GREEN="\[$(tput setab 2 2>/dev/null)\]"
BG_RED="\[$(tput setab 9 2>/dev/null)\]"

# set title
__ps1_set_title() {
  echo -ne "${USER}@${HOSTNAME}:${PWD//$HOME/\~}"
}

# prompt prev exit status
__ps1_promp_command() {
  local retVal=$?
  if [ $retVal = 0 ]; then
    PS1="$(printf '%b' "${RED}[\v]:${GREEN}[\u]@[\H]${RESET}:${YELLOW}[\w]${RESET}:${GREEN}[$retVal]${RESET}${BLACK}🐚${RESET}")"
  else
    PS1="$(printf '%b' "${RED}[\v]:${GREEN}[\u]@[\H]${RESET}:${YELLOW}[\w]${RESET}:${RED}[$retVal]${RESET}${BLACK}🐚${RESET}")"
  fi
  return $retVal
}

# set default prompt
PROMPT_COMMAND="PS1=;__ps1_promp_command;__ps1_set_title;history -a && history -r"
PS2="⚡ "
PS4="$(
  tput cr 2>/dev/null
  tput cuf 6 2>/dev/null
  printf "${GREEN}+%s ($LINENO) +" " $RESET"
)"

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
xterm-color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
  else
    RED=""
    RESET=""
    color_prompt=
  fi
fi

# Set 'man' colors
if [ "$color_prompt" = yes ]; then
  man() {
    env \
      LESS_TERMCAP_mb=$'\e[01;31m' \
      LESS_TERMCAP_md=$'\e[01;31m' \
      LESS_TERMCAP_me=$'\e[0m' \
      LESS_TERMCAP_se=$'\e[0m' \
      LESS_TERMCAP_so=$'\e[01;44;33m' \
      LESS_TERMCAP_ue=$'\e[0m' \
      LESS_TERMCAP_us=$'\e[01;32m' \
      command man "$@"
  }
fi

# git functions
__git_pull() { for d in "$@"; do printf '%-40s' "Pulling $d" && git -C "$d" pull; done; }
__git_push() { for d in "$@"; do printf '%-40s' "Pulling $d" && git -C "$d" push; done; }
__git_clone() {
  local dir="${2:-$HOME/Projects/$(echo "${1//*:\/\//}" | cut -d'.' -f1)/$(echo "${1//*:\/\//}" | awk -F'/' '{print $(NF-1)"/"$NF}')}"
  [ -d "$dir/.git" ] && printf '%-40s' "Pulling $dir" && git -C "$dir" pull || printf '%-40s' "cloning $1" && git clone "$1" "$dir"
}

unset color_prompt force_color_prompt

# enable color support of ls and also add handy aliases
if [ -x "/usr/bin/dircolors" ]; then
  test -r "$HOME/.dircolors" && eval "$(dircolors -b "$HOME/.dircolors")" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias dir='dir --color=auto'
  alias vdir='vdir --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='grep -F --color=auto'
  alias egrep='grep -E --color=auto'
fi

# some more ls aliases
alias q='exit'
alias c='clear'
alias l='ls -CF'
alias ll='ls -l'
alias la='ls -A'
alias lla='ls -laA'
alias em='emacs -nw'
alias dd='dd status=progress'

# sudo aliases
alias _='sudo -n true && sudo'
alias _i='sudo -n true && sudo -i'
alias systemctl='sudo -n true && sudo systemctl || systemctl'

# Alias definitions.
# You may want to put all your additions into a separate file like
# $HOME/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f "$HOME/.bash_aliases" ]; then
  . "$HOME/.bash_aliases"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f "/usr/share/bash-completion/bash_completion" ]; then
    . "/usr/share/bash-completion/bash_completion"
  elif [ -f "/etc/bash_completion" ]; then
    . "/etc/bash_completion"
  fi
fi

# check if local bin folder exist prepend it to $PATH if so
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi
