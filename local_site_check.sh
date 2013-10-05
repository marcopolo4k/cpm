#!/bin/sh
#
# Quick site-checker script written by: Marco Ferrufino
#
# Description: 
#
# How to run this script:
# curl -s --insecure https://raw.github.com/cPanelTechs/TechScripts/master/local_site_check.sh | sh

# This script checks if locally-hosted websites are responding via Apache, and creates a summary_file at:
# /root/site_summary.HOST_IP_ADDRESS.cP.DATE_TAG

# Version: 0.1

# Feel free to customize the following fields:
tmp_dir=/root/cptmp.doms
host_backup_file=/etc/hosts.cppremig.bk.$(date +%Y%m%d%H%M)
summary_file=/root/site_summary.$(hostname -i).cP.$(date +%Y%m%d%H%M)

echo "host_backup_file is: "$host_backup_file
echo "summary_file is: "$summary_file

cp -pv /etc/hosts $host_backup_file

for i in $(cut -d: -f1 /etc/trueuserdomains); do echo -e "127.0.0.1\t\t$i" >> /etc/hosts; done

mkdir $tmp_dir;
for i in $(cut -d: -f1 /etc/trueuserdomains); do
  echo $i;
  curl $i | head -100 | lynx -stdin -dump | awk NF | head > $tmp_dir/$i;
done;
for i in $(\ls -A $tmp_dir/); do
  echo $i: ;
  cat $tmp_dir/$i ;
  echo;echo "============================";
done > $summary_file

# Cleanup
cp -pv $host_backup_file /etc/hosts

if [ -d $tmp_dir ]; then
 rm -rvf $tmp_dir/*; rmdir -v $tmp_dir
else echo "Error: "$tmp_dir" doesn't exist."
fi

echo -e "\nSite Check Complete.  Summary at:\n"$summary_file"\n"
