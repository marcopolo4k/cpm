#!/bin/bash

echo; backlogdir=/usr/local/cpanel/logs/cpbackup; if [ -e $backlogdir ]; then cd $backlogdir; for i in `\ls`; do echo -n $i": "; grep "Started" $i; echo -n "Ended "; \ls -lrth | grep $i | awk '{print $6" "$7" "$8}'; echo -ne " Number of users backed up:\t"; grep "user :" $i | wc -l; done; echo -e "\nTotal users:"; wc -l /etc/trueuserdomains; fi; 

legacy_enabled=$(grep BACKUPENABLE /etc/cpbackup.conf | awk '{print $2'})
legacy_users=$(grep "LEGACY_BACKUP=1" /var/cpanel/users/* | wc -l);
if [ $legacy_users -gt 0 -o $legacy_enabled == "yes" ]; then
 echo -e "\nLegacy Backups are enabled";
 oldxs=$(egrep "LEGACY_BACKUP=0" /var/cpanel/users/* | wc -l);
 echo "EOL Skip file:"; wc -l /etc/cpbackup-userskip.conf;
 if [ $oldxs -gt 0 ]; then echo "Legacy backup exceptions: "$oldxs; fi;
fi

new_enabled=$(grep BACKUPENABLE /var/cpanel/backups/config | awk -F"'" '{print $2}')
if [ "$new_enabled" == "yes" ]; then
 echo -e "\nNew Backups are enabled";
 newxs=$(egrep "BACKUP=0" /var/cpanel/users/* | grep ":BACK" | wc -l);
 if [ $newxs -gt 0 ]; then
  echo "New backup exceptions: "$newxs;
 fi; 
fi

echo; echo
