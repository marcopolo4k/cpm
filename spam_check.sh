#!/bin/sh
# This script creates a few summaries from the mail queue to help you decide if
# the server is sending spam or not.
# 
# Description:
# http://staffwiki.cpanel.net/LinuxSupport/EximSpamOneLiners
# 
#todo: check if this already exists & use that one
#todo: ask user if they want to use existing or not

function get_temp_file_dir () {
 read -p "Choose a directory to store the temporary file cptemp_eximbp.  This will store the output of exim -bp: " -e -i /root temp_dir
 if [ -e $temp_dir ]; then
  echo -e "Thank you.
   This file can be used again to run commands (like 'exigrep user@domain $temp_dir/cptemp_eximbp'.
   Remember to delete it when you're done."
  exim -bp > $temp_dir/cptemp_eximbp
 else
  echo "That directory does not exist."
  get_temp_file_dir
 fi
}

get_temp_file_dir 

#todo: put this in an awk printf statement, report if domain is local/remote at the end:
# Are they local?
# for i in $doms; do echo -n $i": "; grep $i /etc/localdomains; done

echo -e "\nDomains stopping up the queue:"; 
cat $temp_dir/cptemp_eximbp | exiqsumm | sort -n | tail -5;

# Get domains from Exim queue
doms=$(cat $temp_dir/cptemp_eximbp | exiqsumm | sort -n | egrep -v "\-\-\-|TOTAL|Domain" | tail -5 | awk '{print $5}')
echo; 
for j in $doms; do
   dom=$j;
   echo -e "\n\n Count / Subjects for domain = $j:";
   for i in `cat $temp_dir/cptemp_eximbp | grep -B1 $dom | awk '{print $3}'`; do
       exim -Mvh $i | grep Subject; 
   done | sort | uniq -c | sort -n | tail; 
done | awk '{
    split($4,encdata,"?"); 
    command = (" base64 -d -i;echo"); 
    if ($0~/(UTF|utf)-8\?(B|b)/) {
        printf "      "$1" "$2"  "$3" "; 
        print encdata[4] | command; 
        close(command);
        }
    else {print}
    }
    END {printf "\n"}'

# Domains sending:
declare -a sendingaddys=($(egrep "<" $temp_dir/cptemp_eximbp | awk '{print $4}' | sort | uniq -c | sort -n | sed 's/<>/no_address_in_logs/g' | tail -4));
echo -e "\nAddresses sending out: " ${sendingaddys[@]} "\n"| sed 's/ \([0-9]*\) /\n\1 /g'
bigsender=$(echo ${sendingaddys[@]} | awk '{print $NF}'); 
echo -e "So the big sender is:\n"$bigsender

echo; 
for j in $doms; do
    dom=$j; 
    echo "Mails attempting to be sent to domain [$j], from:"; 
    cat $temp_dir/cptemp_eximbp | grep -B1 $dom | egrep -v "\-\-|$dom" | awk '{print $4}' | sort | uniq -c | sort -n | tail -5; 
    echo; 
done
