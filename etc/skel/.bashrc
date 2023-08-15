# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

export PATH=~/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/share/games:/usr/local/sbin:/usr/sbin:/sbin

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

# prompt prev exit status
__ps1_promp_command() {
  local retVal=$?
  [ $retVal = 0 ] && printf '%b' "${GREEN}[$retVal]${RESET}" || printf '%b' "${RED}[ $retVal ]${RESET}"
}

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
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

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

if [ "$color_prompt" = yes ]; then
  PS1=" ${RED}\342\224\214\342\224\200[$([ ${EUID} == 0 ] && printf 'root${YELLOW}@${BLUE}\H' || printf '${GREEN}\u@\H')]\342\224\200${GREEN}[\w]${RESET}${GREEN}\$(__ps1_promp_command) \$ \${RESET}"
else
  PS1='┌──[\u@\H]─[\w]\n└──╼ $(__ps1_promp_command) $ '
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
      man "$@"
  }
fi

unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm* | rxvt*)
  PS1=" ${RED}\342\224\214\342\224\200[$([ ${EUID} == 0 ] && printf 'root${YELLOW}@${BLUE}\H' || printf '${GREEN}\u@\H')]\342\224\200${GREEN}[\w]${RESET}${GREEN}\$(__ps1_promp_command) \$ \${RESET}"
  ;;
*) ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias dir='dir --color=auto'
  alias vdir='vdir --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
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
alias _='sudo -n && sudo'
alias _i='sudo -n && sudo -i'
alias systemctl='sudo -n && systemctl'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# check if local bin folder exist prepend it to $PATH if so
if [ -d $HOME/.local/bin ]; then
  export PATH=$HOME/.local/bin:$PATH
fi
