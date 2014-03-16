#!/bin/bash
#
# Crude Summary of System-Snapshot logs
# by Marco Ferrufino
# 
# These are all piped to less
# Use 'q' to exit less, and then CNTRL-C to cancel out of program
# 
# To use (for example in folder 13):
# cd /root/system-snapshot/13
# sh <(curl -s https://raw.github.com/cPMarco/cpm/master/sys-snap-sum.sh)
#
# These are one-liners, and can be mostly copy/pasted individually
#
# Version 0.0.1


function check_directory () {
    default_dir=$(\pwd | \grep '^\/root\/system-snapshot\/[0-9]*$')
    if ! [ "$default_dir" ] ; then
        clear
        echo "
This script is designed to summarize Sys-Snap output (currently tested with the 
bash version, not perl). Sys-Snap should already be installed and running in 
order for this program to have any data to analyze.  See more info about 
Sys-Snap here:
https://github.com/cPanelTechs/SysSnap
https://staffwiki.cpanel.net/LinuxSupport/SystemMonitorScript

         ***** [ WARNING ] ******
You are not in the default directory (/root/system-snapshot/[0-9]*).
If this is not intentional, then please change to the default directory,
and run again for proper output.

See more information at:
http://wiki address forthcomming...

To exit, press 'CNTRL-C'.
Otherwise, press [Enter] key to continue..."
        read -p "$*"
    fi
}

function print_total_chart () {
    bar_chart=$( 
        wc -l $i | 
        awk -v size=$size '{
            #printf max" "size" "$2 " " $1 " "; 
            printf $2 " " $1 " "; 
            for(i=1; i<=($1/size); ++i) {
                printf "#"
            } 
        }' | 
        #awk '{ print $1,$2,$3,$4,$5 }'
        awk '{ print $1,$2,$3 }'
    ); 
    #printf "%-4s %-4s %-4s %-4s [%4s] \n" $bar_chart; 
    printf "%-4s %-4s [%4s] \n" $bar_chart; 
}

function print_sub_chart () {
    bar_chart=$( 
        echo $1 $2 |
        awk -v size=$size '{
            #printf max" "size" " $1 " "; 
            printf $1 " ";
            for(i=1; i<=($1/size); ++i) {
                printf ".";
            }
        }' | 
        #awk '{ print $1,$2,$3,$4,$5 }'
        awk '{ print $1,$2,$3 }'
    ); 
    #printf "%-4s %-4s %-4s %-4s %-4s %-4s %-4s [%4s] \n" $bar_chart; 
    printf "%-4s [%4s] \n" $bar_chart; 
}

function main () {
    clear
    echo "
[1-CPU] [2-AllSections] [3-I/OWait] [4-Netstat] [5-Sockets] [6-NumberUserProcesses] [7-SystemMemory] [8-MemTopProcs] [9-MySQL] [0-ApacheUp/Dwn]

Choose. Above and below are the same menu choices (lmk which style you prefer).
After you choose, output will be displayed using 'less', so use 'q' to exit, bringing you back.
Use 'CNTRL-C' to exit the program.


1) CPU (c)
2) AllSections (l)
3) I/O Wait (i)
4) Active Internet Connections (t)
5) Network Sockets (o)
6) Number of User Processes (u)
7) System Memory (s)
8) Memory Top Processes (e) 
9) MySQL (m)
0) Apache Up/Down (a)

Less Commonly Used:
Which Service (w)
Alternate Display of All Section Summary (d)


    "
    read screen_choice 

    case "$screen_choice" in

    "1" | "c" )
    for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; egrep "^USER.*ND$" $i; awk '/^USER/,/^Active/' $i | sort -k3 -nr | egrep -v "^USER.*ND$" | head -5; done | 
    awk 'BEGIN{print "\nThe following is output from the ps command, ordered by highest %CPU usage.\n\n";}{if (NF>0) print}' | less
    ;;

    "2" | "l" )
    max=$(\wc -l ./*.log | \awk '{if ($0!~/total/) print $1}' | \sort -n | \tail -1); 
    size=$(max/120);
    for i in $(\ls -rt); do 
        \ls -lah $i; 
        printf "%-17s" "Processes Lines: ";
        print_sub_chart $(awk '/^USER/,/^Active/' $i | wc -l;) $i;
        printf "%-17s" "Netstat Lines: "; 
        print_sub_chart $(awk '/^Active Internet/,/^Active UNIX/' $i | wc -l); 
        printf "%-17s" "Apache Lines: "; 
        print_sub_chart $(awk '/Apache Server Status/,NR==eof' $i | wc -l); 
        printf "%-17s" "Socket Lines: ";  
        print_sub_chart $(awk '/^Active UNIX/,/^$/' $i | wc -l);
        printf "%-17s" "MySQL Lines: "; 
        print_sub_chart $(awk '/\| Id[ ]*\| User/,/^[ ]*Apache/' $i | wc -l);
        echo "Total Lines: "; 
        print_total_chart;
    done | 
    awk 'BEGIN{
        print "\nThe following is a count of lines from each section of Sys-Snap output.\nTotal Lines is a count of all lines in each file, followed by hashes representing the number.\nIf the number of lines increases, this indicates an increase of activity in that section or file.\n(tl;dr: look for the spikes) \n\n";
    }{
        if (NF>0) print
    }' |
    less
    ;;

    "3" | "i" )
    for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; echo "I/O Wait in $i: "; awk '/^procs -/,/^USER/' $i | awk '{ printf "%s", $16" " }'; done |
    awk 'BEGIN{print "\nThe following is output from the sar command, showing I/O Wait.\nIn a healthy server, each number should be < 5.\n\n";}{if (NF>0) print}' | less
    ;;

    "4" | "t" )
    for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; echo "Internet Connections in $i: "; awk '/^Active Internet/,/^Active UNIX/' $i | awk -F / '{if (NF > 1) print $NF}' | sort | uniq -c | sort -nr | head -3; echo "Number of non-labeled connections: "; awk '/^Active Internet/,/^Active UNIX/' $i | egrep '\-[ ]*$' | wc -l; done |
    awk 'BEGIN{print "\nThe following is output from the netstat command, showing internet connections by service.\n\n";}{if (NF>0) print}' | less
    ;;

    "5" | "o" )
    for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; echo "Internet Connections in $i: "; awk '/^Active UNIX/,/^$/' $i | awk -F / '{if (NF > 1) print $NF}' | sort | uniq -c | sort -nr | head -3; echo "Number of non-labeled connections: "; awk '/^Active Internet/,/^Active UNIX/' $i | egrep '  \-[ ]*$' | wc -l; done |
    awk 'BEGIN{print "\nThe following is output from the netstat command, showing unix network socket connections by service.\n\n";}{if (NF>0) print}' | less
    ;;

    "6" | "u" )
    for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; echo "Number of processes by user in $i: "; awk '/^USER/,/^Active/' $i | sort -k3 -r | awk '{print $1}' | sort | uniq -c | sort -nr | head -5; done |
    awk 'BEGIN{print "\nThe following is a count of user processes by each linux user, from the ps command.\n\n";}{if (NF>0) print}' | less
    ;;

    "7" | "s" )
    for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; grep ^Mem $i; done |
    awk 'BEGIN{print "\nThe following is memory information from /proc/meminfo.\n\n";}{if (NF>0) print}' | less
    ;;

    "8" | "e" )
    for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; awk '/^USER/,/^Active/' $i | sort -k4 -nr | head -3; done |
    awk 'BEGIN{print "\nThe following is output from the ps command, ordered by highest memory (%MEM) usage.\n\n";}{if (NF>0) print}' | less
    ;;

    "9" | "m" )
    for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; awk '/---\+$/,NR==eof {if($1~/\|/ && $2!~"Id")print}' $i | awk -F"|" '{for (i=1;i<=NF;i=i+1) {gsub(/^[ ]+$/,"\t_\t",$i); if($i~/[a-zA-Z]+[ ][a-zA-Z]+/){gsub(/ /,"_",$i)}; printf " "$i" "}; print ""}' | sort -n -r -k6; done |
    awk 'BEGIN{print "\nThe following is MySQL output from the mysqladmin command, ordered by how long the process has been running.\nIts possible that shorter running processes contribute more to load than longer ones, but its less likely and more difficult to enumerate (please lmk if you know a good way - Marco)\n\n";}{if (NF>0) print}' | less
    ;;

    "0" | "a" )
    for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; awk '/^[ ]*Server uptime/,/load$/' $i; done |
    awk 'BEGIN{print "\nThe following is output from the httpd status command, letting you if/when Apache has been down.\n\n";}{if (NF>0) print}' | less
    ;;

    "w" )
    for i in $(\ls -rt); do echo; echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"; \ls -lah $i; awk '/^Active Internet/,/^Active UNIX/' $i | awk -F / '{if (NF > 1) print $NF}' | sort | uniq -c | sort -nr | head -3; done |
    awk 'BEGIN{print "\nThe following is another listing of services from netstat.\n\n";}{if (NF>0) print}' | less
    ;;

    "d" )
    for i in $(\ls -rt); do \ls -lah $i; echo -n "Processes Lines: "; awk '/^USER/,/^Active/' $i | wc -l; echo -n "Netstat Lines: "; awk '/^Active Internet/,/^Active UNIX/' $i | wc -l; echo -n "Apache Lines: "; awk '/Apache Server Status/,NR==eof' $i | wc -l; echo -n "Socket Lines: ";  awk '/^Active UNIX/,/^$/' $i | wc -l; echo -n "MySQL Lines: "; awk '/\| Id[ ]*\| User/,/---+$/' $i | wc -l; echo "Total Lines: "; max=$(wc -l ./*.log | awk '{if ($0!~/total/) print $1}' | sort | tail -1); bar_chart=$( wc -l $i | awk -v max=$max '{ size=1; while (max>50) { max=int(max/2); size++; }; printf $2 " " $1 " "; for(i=1; i<=($1/size); ++i) {printf "#"} }' | awk '{print $1,$2,$3}'); printf "%-4s %-4s [%4s] \n" $bar_chart; done |
    awk 'BEGIN{print "\nThe following is a count of lines from each section of Sys-Snap output.\nTotal Lines is a count of all lines in each file, followed by hashes representing the number.\nIf the number of lines increases, this indicates an increase of activity in that section or file.\n(So, look for the spikes) \n\n";}{if (NF>0) print}' | less
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

#############################
# Main Code
###############

check_directory

while :
do
    main
    echo "Press [CTRL+C] to stop.."
    #sleep 1
done
