#!/bin/bash
# Quick backup report script
# This tries to notice if new and/or legacy backups are enabled to report the number of skipped users as well
# Description: https://staffwiki.cpanel.net/bin/view/LinuxSupport/CPanelBackups
#
# How to run this script:
# curl -s --insecure https://raw.github.com/cPMarco/cpm/master/backup_report.sh | sh

backlogdir=/usr/local/cpanel/logs/cpbackup;

# look at start, end times.  print number of users where backup was attempted
function print_start_end_times () {
echo -e "\nCurrent Backup Logs in "$backlogdir":\n"
if [ -e $backlogdir ]; then
 cd $backlogdir;
 for i in `\ls`; do
  echo -n $i": "; grep "Started" $i; echo -n "Ended ";
  \ls -lrth | grep $i | awk '{print $6" "$7" "$8}';
  echo -ne " Number of users backed up:\t";  grep "user :" $i | wc -l;
 done;
 echo -e "\nTotal users:"; wc -l /etc/trueuserdomains;
fi;
}

# check if legacy or new backups are enabled.  if each one is, then show how many users are skipped
function check_legacy_or_new () {
legacy_enabled=$(grep BACKUPENABLE /etc/cpbackup.conf | awk '{print $2'})
legacy_users=$(grep "LEGACY_BACKUP=1" /var/cpanel/users/* | wc -l);
if [ $legacy_enabled == "yes" ]; then
 echo -e "\nLegacy Backups are enabled";
 oldxs=$(egrep "LEGACY_BACKUP=0" /var/cpanel/users/* | wc -l);
 if [ $oldxs -gt 0 ]; then echo "Number of real Legacy backup exceptions: "$oldxs; fi;
 echo -e "\nExtra Information: This skip file should no longer be used"; wc -l /etc/cpbackup-userskip.conf;
elif [ $legacy_users -gt 0 -a $legacy_enabled == "no" ]; then
 echo -e "\nExtra Information: Legacy Backups aren't enabled, but there are some users ready to use them."
fi
}

# check if new backups are enabled
function check_new_backups() {
new_enabled=$(grep BACKUPENABLE /var/cpanel/backups/config | awk -F"'" '{print $2}')
if [ "$new_enabled" == "yes" ]; then
 echo -e "\nNew Backups are enabled";
 newxs=$(egrep "BACKUP=0" /var/cpanel/users/* | grep ":BACK" | wc -l);
 if [ $newxs -gt 0 ]; then
  echo "New backup exceptions: "$newxs;
 fi;
fi
}

# Run all functions
print_start_end_times 
check_legacy_or_new 
check_new_backups
echo; echo
