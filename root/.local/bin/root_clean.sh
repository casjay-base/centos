#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202305090019-git
# @@Author           :  Jason Hempstead
# @@Contact          :  git-admin@casjaysdev.com
# @@License          :  LICENSE.md
# @@ReadME           :  root_clean.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Tuesday, Sep 06, 2022 15:18 EDT
# @@File             :  root_clean.sh
# @@Description      :  Remove old log files
# @@Changelog        :  newScript
# @@TODO             :  Refactor code
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  bash/system
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "/etc/logrotate.d/btmp" ] && rm -Rf "/etc/logrotate.d/btmp"
[ -f "/etc/logrotate.d/wtmp" ] && rm -Rf "/etc/logrotate.d/wtmp"
[ -z "$(builtin type -P clean-system 2>/dev/null)" ] || clean-system --raw
