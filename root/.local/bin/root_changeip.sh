#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202201210244-git
# @@Author           :  Jason Hempstead
# @@Contact          :  git-admin@casjaysdev.com
# @@License          :  LICENSE.md
# @@ReadME           :  root_changeip.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Tuesday, Sep 06, 2022 15:18 EDT
# @@File             :  root_changeip.sh
# @@Description      :  update up address
# @@Changelog        :  newScript
# @@TODO             :  Refactor code
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  bash/system
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -n "$(which changeip 2>/dev/null)" ] && changeip
