#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202201210244-git
# @@Author           :  Jason Hempstead
# @@Contact          :  git-admin@casjaysdev.com
# @@License          :  LICENSE.md
# @@ReadME           :  update-resolv.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Tuesday, Sep 06, 2022 15:18 EDT
# @@File             :  update-resolv.sh
# @@Description      :  Update the Resolver config
# @@Changelog        :  newScript
# @@TODO             :  Refactor code
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  bash/system
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__fetch() {
  curl -q -LSsf "https://github.com/casjay-base/centos/raw/main/etc/resolv.conf" -o "/tmp/resolv.conf"
  return $?
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -f "/etc/resolv.conf " ]; then
  chattr -i "/etc/resolv.conf"
  mv -f "/etc/resolv.conf" "/tmp/resolv.bak.conf"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if __fetch; then
  [ -f "/tmp/resolv.conf" ] && mv -f "/tmp/resolv.conf" "/etc/resolv.conf"
else
  [ -f "/tmp/resolv.bak.conf" ] && mv -f "/etc/resolv.conf" "/tmp/resolv.bak.conf"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "/tmp/resolv.conf" ] && rm -Rf "/tmp/resolv.conf"
[ -f "/tmp/resolv.bak.conf" ] && rm -Rf "/tmp/resolv.bak.conf"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
chattr +i "/etc/resolv.conf"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end
