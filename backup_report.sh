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
 if [ "$new_enabled" == "yes" ]; then new_status='\033[1;32m'Enabled'\033[0m'
 else new_status='\033[1;31m'Disabled'\033[0m'
 fi
 echo -e "\nNew Backups = $new_status"
}

# check if legacy or new backups are enabled.  if each one is, then show how many users are skipped
function check_legacy_backups() {
 legacy_enabled=$(grep BACKUPENABLE /etc/cpbackup.conf | awk '{print $2'})
 if [ $legacy_enabled == "yes" ]; then legacy_status='\033[1;32m'Enabled'\033[0m'
 else legacy_status='\033[1;31m'Disabled'\033[0m'
 fi
 echo -e "Legacy Backups = $legacy_status";
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
if [ $legacy_enabled == "yes" ]; then
 echo -e "\nLegacy Backups Exceptions";
 oldxs=$(egrep "LEGACY_BACKUP=0" /var/cpanel/users/* | wc -l);
 if [ $oldxs -gt 0 ]; then echo "Number of real Legacy backup exceptions: "$oldxs; fi;
 echo -e "\nExtra Information: This skip file should no longer be used"; wc -l /etc/cpbackup-userskip.conf;
elif [ $legacy_users -gt 0 -a $legacy_status == "Disabled" ]; then
 echo -e "\nExtra Information: Legacy Backups aren't enabled, but there are $legacy_users users ready to use them."
fi
}

function list_new_exceptions() {
if [ "$new_enabled" == "yes" ]; then
 newxs=$(egrep "BACKUP=0" /var/cpanel/users/* | grep ":BACK" | wc -l);
 echo -e "\nNew Backups exceptions: $newxs";
 newen=$(egrep "BACKUP=1" /var/cpanel/users/* | grep ":BACK" | wc -l);
 echo -e "New Backup users enabled: "$newen
fi
}

count_local_new_backups() {
echo -e "\n\nA count of the backup files on local disk currently:"
new_backup_dir=$(awk '/BACKUPDIR/ {print $2}' /var/cpanel/backups/config)
number_new_backups=$(\ls $new_backup_dir/*/accounts/ | wc -l)
echo -e "\nNew backups in $new_backup_dir/*/accounts: "$number_new_backups
}

count_local_legacy_backups() {
legacy_backup_dir=$(awk '/BACKUPDIR/ {print $2}' /etc/cpbackup.conf)
echo -e "\nLegacy backups in $legacy_backup_dir/cpbackup: "
for freq in daily weekly monthly; do 
 echo -n $freq": "; 
 \ls $legacy_backup_dir/cpbackup/$freq | egrep -v "^dirs$|^files$|cpbackup|status" | sed 's/\.tar.*//g' | sort | uniq | wc -l;
done
}

# Run all functions
check_new_backups
check_legacy_backups
print_start_end_times 
list_legacy_exceptions
list_new_exceptions
count_local_new_backups
count_local_legacy_backups
echo; echo
