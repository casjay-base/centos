# set title
__ps1_set_title() { echo -ne "${USER}@${HOSTNAME}:${PWD//$HOME/\~}"; }

# prompt prev exit status
__ps1_promp_command() {
  local retVal=$?
  if [ $retVal = 0 ]; then
    PS1="${RED}[\v]:${GREEN}[\u]@[\H]${RESET}:${YELLOW}[\w]${RESET}:${GREEN}[$retVal]${RESET}${BLACK}🐚${RESET}"
  else
    PS1="${RED}[\v]:${GREEN}[\u]@[\H]${RESET}:${YELLOW}[\w]${RESET}:${RED}[$retVal]${RESET}${BLACK}🐚${RESET}"
  fi
  return $retVal
}

# set default prompt
PROMPT_COMMAND="__ps1_promp_command;__ps1_set_title;history -a && history -r"
PS2="⚡ "
PS4="$(
  tput cr 2>/dev/null
  tput cuf 6 2>/dev/null
  printf "${GREEN}+%s ($LINENO) +" " $RESET"
)"
