#!/bin/bash

# Crude Summary of System-Snapshot logs
# tl;dr
# These are all piped to less
# Use 'q' to exit less, and then CNTRL-C to cancel out of program
# 
#
#
# More detailed how to use:
#
# root@cent58-x64 [~]# cd /root/system-snapshot/
# 00/      02/      04/      06/      08/      10/      12/      14/      16/      18/      20/      22/      current  
# 01/      03/      05/      07/      09/      11/      13/      15/      17/      19/      21/      23/      
# root@cent58-x64 [~]# cd /root/system-snapshot/13/
# root@cent58-x64 [~/system-snapshot/13]# pwd
# /root/system-snapshot/13
# root@cent58-x64 [~/system-snapshot/13]# sh <(curl -s https://raw.github.com/cPMarco/cpm/master/system_summary.sh)
# 
# Then, click the number or letter to access the less output.  Exit less with 'q'.  Then, you can select a different screen.
# Repeat.
# The 'CPU' screen is ps output, organized by CPU%.  It's like looking at top, but from every file in your current directory


function main () {
clear # Clear the screen.
echo "Choose [1-CPU] [2-AllSections] [3-I/OWait] [4-Netstat] [5-Sockets] [6-NumberUserProcesses] [7-SystemMemory] [8-MemTopProcs] [9-MySQL] [0-ApacheUp/Dwn]"

read screen_choice 

case "$screen_choice" in

"1" | "c" )
for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; egrep "^USER.*ND$" $i; awk '/^USER/,/^Active/' $i | sort -k3 -nr | egrep -v "^USER.*ND$" | head -5; done | awk NF | less
;;

"2" | "l" )
for i in $(\ls -rt); do \ls -lah $i; echo -n "Processes Lines: "; awk '/^USER/,/^Active/' $i | wc -l; echo -n "Netstat Lines: "; awk '/^Active Internet/,/^Active UNIX/' $i | wc -l; echo -n "Apache Lines: "; awk '/Apache Server Status/,NR==eof' $i | wc -l; echo -n "Socket Lines: ";  awk '/^Active UNIX/,/^$/' $i | wc -l; echo -n "MySQL Lines: "; awk '/\| Id[ ]*\| User/,/---+$/' $i | wc -l; echo "Total Lines: "; max=$(wc -l ./*.log | awk '{if ($0!~/total/) print $1}' | sort | tail -1); bar_chart=$( wc -l $i | awk -v max=$max '{ size=1; while (max>50) { max=int(max/2); size++; }; printf $2 " " $1 " "; for(i=1; i<=($1/size); ++i) {printf "#"} }' | awk '{print $1,$2,$3}'); printf "%-4s %-4s [%4s] \n" $bar_chart; done | awk NF | less
;;

"3" | "i" )
for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; echo "I/O Wait in $i: "; awk '/^procs -/,/^USER/' $i | awk '{ printf "%s", $16" " }'; done | less
;;

"4" | "n" )
for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; echo "Internet Connections in $i: "; awk '/^Active Internet/,/^Active UNIX/' $i | awk -F / '{if (NF > 1) print $NF}' | sort | uniq -c | sort -nr | head -3; echo "Number of non-labeled connections: "; awk '/^Active Internet/,/^Active UNIX/' $i | egrep '\-[ ]*$' | wc -l; done | awk NF | less
;;

"5" | "s" )
for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; echo "Internet Connections in $i: "; awk '/^Active UNIX/,/^$/' $i | awk -F / '{if (NF > 1) print $NF}' | sort | uniq -c | sort -nr | head -3; echo "Number of non-labeled connections: "; awk '/^Active Internet/,/^Active UNIX/' $i | egrep '  \-[ ]*$' | wc -l; done | awk NF | less
;;

"6" | "n" )
for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; echo "Number of processes by user in $i: "; awk '/^USER/,/^Active/' $i | sort -k3 -r | awk '{print $1}' | sort | uniq -c | sort -nr | head -5; done | less
;;

"7" | "s" )
for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; grep ^Mem $i; done | less
;;

"8" | "e" )
for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; awk '/^USER/,/^Active/' $i | sort -k4 -nr | head -3; done | less
;;

"9" | "m" )
for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; awk '/---\+$/,NR==eof {if($1~/\|/ && $2!~"Id")print}' $i | awk -F"|" '{for (i=1;i<=NF;i=i+1) {gsub(/^[ ]+$/,"\t_\t",$i); if($i~/[a-zA-Z]+[ ][a-zA-Z]+/){gsub(/ /,"_",$i)}; printf " "$i" "}; print ""}' | sort -n -r -k6; done | awk NF | less
;;

"0" | "a" )
for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; awk '/^[ ]*Server uptime/,/load$/' $i; done | less
;;

# Add info for later.

          * )
   # Default option.      
   # Empty input (hitting RETURN) gets here, too.
   echo
   echo "Not an option."
  ;;

esac

echo

#exit 0
}

while :
do
    main
    echo "Press [CTRL+C] to stop.."
    #sleep 1
done
