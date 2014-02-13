#!/bin/sh
#
# Quick site-checker script written by: Marco Ferrufino
#
# Description: 
#
# How to run this script:
# curl -s --insecure https://raw.github.com/cPMarco/cpm/master/local_site_check.sh | sh

# This script checks if locally-hosted websites are responding via Apache, and creates a summary_file at:
# /root/site_summary.HOST_IP_ADDRESS.cP.DATE_TAG

# Version: 0.2.5
# ToDo:
# handle multiple options at same time
# allow a timeout variable as option
# currently, two control panels can only use 127.0.0.1, or dns resolution.  Need to use the local IP:
#  plesk, ensim

# Feel free to customize the following fields:
tmp_dir=/root/cptmp.doms
summary_file=/root/.site_summary.$(hostname -i).cP.$(date +%Y%m%d).$(date +%H).$(date +%M)

debug() {
 debug="off"
 if [ "$debug" = "on" ]; then
  echo -e $1
 fi
}

print_help(){
	debug "\nThe help section:"
	debug "dns_resolution is ${dns_resolution}"
	debug "local_resolution is ${local_resolution}"
	debug "use_trueuserdomains is ${use_trueuserdomains}"
	debug "use_localdomains is ${use_localdomains}"
	echo 'usage:'
	echo 'sh local_site_check.sh'
	echo
	echo 'optional arguments (name resolution):'
	echo '-d use [D]NS resolution to get site content'
	echo '-e use local resolution only (place 127.0.0.1 in /[E]tc/hosts for [E]ach domain) (this is default)'
	echo
	echo 'optional arguments (to get domain list):'
	echo '-t use /etc/[T]rueuserdomains (this is default for non-cPanel servers)'
	echo '-l use /etc/[L]ocaldomains (can only be used, and is default on cPanel servers)'
	echo
	echo 'optional arguments (other):'
	echo '-o <directory name>, specify output directory'
	echo '-h print this help screen'
	echo; echo; exit 1
}

# Set default options
pver=$(cat /usr/local/psa/version 2>/dev/null); 
cver=$(cat /usr/local/cpanel/version 2>/dev/null); 
dver=$(/usr/local/directadmin/directadmin c 2>/dev/null | grep ^version); 
ever=$(cat /usr/lib/opcenter/VERSION 2>/dev/null);

dns_resolution="0"
local_resolution="1"
use_trueuserdomains="1"
use_localdomains="0"

if [ "$cver" ]; then
    use_trueuserdomains="0"
    use_localdomains="1"
fi

# Hopefully temporary until I get the commands for these two
if [ "$pver" -o "$ever" ]; then
    dns_resolution="1"
    local_resolution="0"
fi

debug "\nAfter setting defaults:"
debug "dns_resolution is ${dns_resolution}"
debug "local_resolution is ${local_resolution}"
debug "use_trueuserdomains is ${use_trueuserdomains}"
debug "use_localdomains is ${use_localdomains}" 

# Get options (code from cpmig)
# I wasn't able to make this work inside a function.  Perhaps someone can tell me why.
while getopts ":o:detlh" opt; do
    case $opt in
        d) dns_resolution="1"; local_resolution="0";;
        e) local_resolution="1"; dns_resolution="0";;
        t) use_trueuserdomains="1"; use_localdomains="0";;
        l) use_localdomains="1"; use_trueuserdomains="0";;
        o) output_dir="$OPTARG";;
        h) print_help;;
        \?) echo "invalid option: -$OPTARG"; echo; print_help;;
        :) echo "option -$OPTARG requires an argument."; echo; print_help;;
    esac
    debug "\nAfter getting opts:"
    debug "dns_resolution is ${dns_resolution}"
    debug "local_resolution is ${local_resolution}"
    debug "use_trueuserdomains is ${use_trueuserdomains}"
    debug "use_localdomains is ${use_localdomains}" 
done
# no required variables, so don't need this:
#if [[ $# -eq 0 || -z $sourceserver ]]; then print_help; fi  # check for existence of required var

# Set output
if [[ $output_dir != '' ]]; then
    debug "output_dir is ${output_dir}"
    temp_dir=$(echo $output_dir | sed 's/\/$//')
    debug "temp_dir is ${temp_dir}"
    summary_file=$temp_dir/site_summary.$(hostname -i).cP.$(date +%Y%m%d).$(date +%H).$(date +%M)
else
    summary_file=/root/site_summary.$(hostname -i).cP.$(date +%Y%m%d).$(date +%H).$(date +%M)
fi

# Functions
# The first two set the $domain_list
if_trueuserdomains() {
    debug "Testing if_trueuserdomains()..."
    if [[ $use_trueuserdomains == "1" ]]; then
    debug "Running if_trueuserdomains()..."
        domain_list=$(cut -d: -f1 /etc/trueuserdomains)
        debug "domain_list is ${domain_list}"
        mkdir $tmp_dir;
        #for dom in $(cut -d: -f1 /etc/trueuserdomains); do
        for u in $(cat /etc/trueuserdomains | \cut -d: -f2 | \tr -d ' '); do
            if [ "$dver" ]; then
                dom_ip=$(head -1 /usr/local/directadmin/data/users/$u/user_ip.list)
                debug "dom_ip is ${dom_ip}"
            else dom_ip=127.0.0.1
            fi
            echo -e "$dom_ip\t\t$dom" >> /root/doms_to_add
        done
    fi
}

if_localdomains() {
    debug "Testing if_localdomains()..."
    if [[ $use_localdomains == "1" ]]; then
        debug "Running if_localdomains()..."
        if [ ! -e /etc/localdomains ]; then
            echo -e "No /etc/localdomains file found.\nPlease try again"
            exit 0
        fi
        domain_list=$(cat /etc/localdomains)
        debug "domain_list is ${domain_list}"
        mkdir $tmp_dir;
        # this is cheating.  ill fix later
        for dom in $(cat /etc/localdomains); do
            udata_file=/var/cpanel/userdata/$(/scripts/whoowns $dom)/$dom
            if [ -e "$udata_file" ]; then
                dom_ip=$(\grep ^ip /var/cpanel/userdata/$(/scripts/whoowns $dom)/$dom | \cut -d: -f2 | \tr -d ' ')
            else
                echo -e "Domain's IP not found in:\n/var/cpanel/userdata/$dom/main \nIt's probably a sub/parked/addon domain, but here's /scripts/whoowns $dom"
                /scripts/whoowns $dom; echo
            fi
            debug "$dom_ip\t$dom"
            echo -e "$dom_ip\t$dom" >> /root/doms_to_add
        done
    fi
}

# Both of these call main()
if_local_resolution() {
    debug "\nTesting if_local_resolution()..."
    if [[ $local_resolution == "1" ]]; then
        debug "Running if_local_resolution()..."

        # Backup hosts file
        host_backup_file=/etc/hosts.cppremig.bk.$(date +%Y%m%d).$(date +%H).$(date +%M)
        debug "host_backup_file is ${host_backup_file}"
        cp -pv /etc/hosts $host_backup_file

        # Add lines into /etc/hosts to ensure we only look at the locally hosted versions of the websites:
        cat /root/doms_to_add >> /etc/hosts

        main

        # Cleanup
        cp -pv $host_backup_file /etc/hosts
        debug "host_backup_file is ${host_backup_file}"
    fi
}

if_dns_resolution() {
    debug "\nTesting if_dns_resolution()..."
    if [[ $dns_resolution == "1" ]]; then
        debug "\nRunning if_dns_resolution()..."
        main
    fi
}

main (){
    debug "\nRunning main().  domain_list is ${domain_list}"
    if [ ! -d $tmp_dir ]; then mkdir $tmp_dir; fi
    for i in $domain_list; do
        echo $i
        #command -v lynx >/dev/null 2>&1 || { echo >&2 "I require lynx but it's not installed.  Aborting."; exit 1; }
        #command -v curl >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed.  Aborting."; exit 1; }
        2>/dev/null 1>&2 command -v lynx
        if [[ $? -eq 0 ]]; then
            curl -r 0-499 --connect-timeout 1 $i | lynx -stdin -dump | awk NF | head > $tmp_dir/$i
        else
            curl -r 0-499 --connect-timeout 1 $i | awk NF | head > $tmp_dir/$i
        fi
    done;
    for i in $(\ls -A $tmp_dir/); do
        dom_ip=$(grep $i /root/doms_to_add | awk '{print $1}')
        hname=$(hostname)
        echo $i" on "$hname" using IP "$dom_ip
        cat $tmp_dir/$i
        echo;echo "============================";
    done > $summary_file

    # Cleanup
    echo -e "\nCleanup:"
    if [ -d $tmp_dir ]; then
        \rm -rvf $tmp_dir/*; \rmdir -v $tmp_dir
    else echo "Error: "$tmp_dir" doesn't exist."
    fi
    \rm -v /root/doms_to_add
}

# All done
print_complete() {
    echo -e "\nSite Check Complete.\n
Here are the options that were used:
    DNS Resolution: ${dns_resolution} 
    Local IP's: ${local_resolution}
    trueuserdomains: ${use_trueuserdomains}
    localdomains: ${use_localdomains}
    
Summary at:\n"$summary_file"\n"
}


# Run code
# wish I could put getopts in a function here, not sure why I can't
if_trueuserdomains
if_localdomains
if_local_resolution # calls main()
if_dns_resolution # calls main()
print_complete
