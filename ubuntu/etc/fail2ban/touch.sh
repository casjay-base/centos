#!/bin/sh
for log in $(cat /etc/fail2ban/logs.txt) ; do touch $log ; done
