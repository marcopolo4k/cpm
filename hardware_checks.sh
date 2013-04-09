#!/bin/bash

# Establish colors (White for heading, red for errors)
white="\E[37;44m\033[7m";
clroff="\033[0m";
red="\E[37;41m\033[4m";

# If an error that returns positive, print the error in red first, then the results
function checkfor() {
    if [ "$1" ];
     then echo -e $red"$2"$clroff; echo "$1";
     fi
}

echo -ne "\nEnvironment: ";
strings -1 /var/cpanel/envtype;

# make sure not Cloudlinux, before checking for vz errors
cl_check=$(lsmod|grep lve; uname -a|grep -o lve;);
if [ ! "cl_check" ]; then
 if [[ -e /proc/user_beancounters && ! "$cl_check" ]];
  then vzerr=$(awk 'NR>2{if($1~/[0-9]/&&$7>0)print$2" failcnt "$7; else if($1!~/[0-9]/&&$6>0)print$1" failcnt "$6}' /proc/user_beancounters;);
  checkfor "$vzerr" "The VPS is running out of resources:"
 fi;
 echo;
fi
echo;

echo -ne "\n\nSELinux: ";
if [ -e /etc/selinux/config ];
 then grep ^SELINUX /etc/selinux/config|cut -d"=" -f2;
 else echo "none";
fi;
ps -ef | grep gd[m];

w; echo;
dfi=$(df -i|awk 'split($5,a,"%") {if(a[1]~/[0-9]/ && a[1]>85) print}');
dff=$(df -ah|awk 'split($5,a,"%") {if(a[1]~/[0-9]/ && a[1]>85) print}');
if [ "$dff" -o "$dfi" ];
 then echo -e $red$dff"\nInodes:\n"$dfi$clroff;
fi;
echo;

lsattr -ld /;
dmesg | egrep -i "failed|timed out|[^c]hang|BAD|SeekComplete Error|DriveStatusError|UncorrectableError|oom-kill|comm:.*Not|Drive timeout detected" | uniq ;

# if Drive timeout detected, see ticket 3874851.  not sure if that's anything or not

echo "Segfaults in messages:";
tail -1000 /var/log/messages|egrep -i "segfault|I/O error"|uniq;

fatal_hd_error=$(dmesg|fgrep "SeekComplete Error")
if [ "$fatal_hd_error" ];
 then echo -e $red"This error indicates a failing HD in dmesg:"$clroff"\n"$fatal_hd_error"\n"
fi

fatal_hd_error_2=$(dmesg|fgrep "auto reallocate failed")
if [ "$fatal_hd_error_2" ];
 then echo -e $red"This error indicates a failing HD in dmesg:"$clroff"\n"$fatal_hd_error_2"\n"
fi

echo -e "\n\nDisable Files:";
\ls /etc|grep --color disable|egrep -v "entropy|interch";
