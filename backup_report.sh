#!/bin/bash
# Quick backup report script
#
# Description: https://staffwiki.cpanel.net/bin/view/LinuxSupport/CPanelBackups
#
# How to run this script:
# curl -s --insecure https://raw.github.com/cPMarco/cpm/master/backup_report.sh | sh

# this shows backups enabled or disabled but i need to return the value to the check functions

backlogdir=/usr/local/cpanel/logs/cpbackup;

# check if new backups are enabled
function check_new_backups() {
 new_enabled=$(grep BACKUPENABLE /var/cpanel/backups/config | awk -F"'" '{print $2}')
 if [ "$new_enabled" == "yes" ]; then new_status="Enabled"
 else new_status="Disabled"
 fi
 echo -e "\nNew Backups = $new_status"
}

# check if legacy or new backups are enabled.  if each one is, then show how many users are skipped
function check_legacy_backups() {
 legacy_enabled=$(grep BACKUPENABLE /etc/cpbackup.conf | awk '{print $2'})
 if [ $legacy_enabled == "yes" ]; then legacy_status="Enabled"
 else legacy_status="Disabled"
 fi
 echo "Legacy Backups = $legacy_status";
}

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

function list_legacy_exceptions() {
legacy_users=$(grep "LEGACY_BACKUP=1" /var/cpanel/users/* | wc -l);
if [ $legacy_status == "Enabled" ]; then
 echo -e "\nLegacy Backups Exceptions";
 oldxs=$(egrep "LEGACY_BACKUP=0" /var/cpanel/users/* | wc -l);
 if [ $oldxs -gt 0 ]; then echo "Number of real Legacy backup exceptions: "$oldxs; fi;
 echo -e "\nExtra Information: This skip file should no longer be used"; wc -l /etc/cpbackup-userskip.conf;
elif [ $legacy_users -gt 0 -a $legacy_status == "Disabled" ]; then
 echo -e "\nExtra Information: Legacy Backups aren't enabled, but there are $legacy_users users ready to use them."
fi
}

function list_new_exceptions() {
if [ "$new_status" == "Enabled" ]; then
 newxs=$(egrep "BACKUP=0" /var/cpanel/users/* | grep ":BACK" | wc -l);
 echo -e "\nNew Backups exceptions: $newxs";
fi
}

# Run all functions
check_new_backups
check_legacy_backups
print_start_end_times 
list_legacy_exceptions
list_new_exceptions
echo; echo
