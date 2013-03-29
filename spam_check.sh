#!/bin/sh
# This script creates a few summaries from the mail queue to help you decide if
# the server is sending spam or not.
# 
# Description:
# http://staffwiki.cpanel.net/LinuxSupport/EximSpamOneLiners
# 
# Choose a directory to store the temporary file.  This will store the output of exim -bp
temp_dir=/root/
exim -bp > $temp_dir/cptemp_eximbp

echo -e "\nDomains stopping up the queue:"; 
cat $temp_dir/cptemp_eximbp | exiqsumm | sort -n | tail -5;
doms=$(cat $temp_dir/cptemp_eximbp | exiqsumm | sort -n | egrep -v "\-\-\-|TOTAL" | tail -5 | awk '{print $5}')
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
    END {print}'

# Domains sending:
declare -a sendingaddys=($(egrep "<" $temp_dir/cptemp_eximbp | awk '{print $4}' | sort | uniq -c | sort -n | sed 's/<>/no_address_in_logs/g' | tail -4));
echo -e "Addresses sending out: " ${sendingaddys[@]} "\n"| sed 's/ \([0-9]*\) /\n\1 /g'
bigsender=$(echo ${sendingaddys[@]} | awk '{print $NF}'); echo -e "So the big sender is:\n"$bigsender

# Are they local?
# for i in $doms; do echo -n $i": "; grep $i /etc/localdomains; done

echo; for j in $doms; do dom=$j; echo "Mails attempting to be sent to domain [$j], from:"; cat $temp_dir/cptemp_eximbp | grep -B1 $dom | egrep -v "\-\-|$dom" | awk '{print $4}' | sort | uniq -c | sort -n | tail -5; echo; done

