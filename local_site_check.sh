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

# Version: 0.2

# Feel free to customize the following fields:
tmp_dir=/root/cptmp.doms
summary_file=/root/site_summary.$(hostname -i).cP.$(date +%Y%m%d).$(date +%H).$(date +%M)

debug() {
 debug="off"
 if [ "$debug" = "on" ]; then
  echo -e $1
 fi
}

print_help(){
	debug "\nin the help section:"
	debug "dns_resolution is ${dns_resolution}"
	debug "local_resolution is ${local_resolution}"
	debug "use_trueuserdomains is ${use_trueuserdomains}"
	debug "use_localdomains is ${use_localdomains}"
	echo 'usage:'
	echo 'sh local_site_check.sh'
	echo
	echo 'optional arguments:'
	echo '-d use [D]NS resolution to get site content'
	echo '-e use local resolution only (place 127.0.0.1 in /[E]tc/hosts for [E]ach domain) (this is default)'
	echo '-t use /etc/[T]rueuserdomains (this is default for non-cPanel servers)'
	echo '-l use /etc/[L]ocaldomains (can only be used, and is default on cPanel servers)'
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

debug "\njust after setting defaults:"
debug "dns_resolution is ${dns_resolution}"
debug "local_resolution is ${local_resolution}"
debug "use_trueuserdomains is ${use_trueuserdomains}"
debug "use_localdomains is ${use_localdomains}" 

# Get options (code from cpmig)
# I wasn't able to make this work inside a function.  Perhaps someone can tell me why.
while getopts "detlh" opt; do
    case $opt in
        d) dns_resolution="1"; local_resolution="0";;
        e) local_resolution="1"; dns_resolution="0";;
        t) use_trueuserdomains="1"; use_localdomains="1";;
        l) use_localdomains="1"; use_trueuserdomains="1";;
        h) print_help;;
        \?) echo "invalid option: -$OPTARG"; echo; print_help;;
        :) echo "option -$OPTARG requires an argument."; echo; print_help;;
    esac
    debug "\nafter getting opts:"
    debug "dns_resolution is ${dns_resolution}"
    debug "local_resolution is ${local_resolution}"
    debug "use_trueuserdomains is ${use_trueuserdomains}"
    debug "use_localdomains is ${use_localdomains}" 
done
# no required variables, so don't need this:
#if [[ $# -eq 0 || -z $sourceserver ]]; then print_help; fi  # check for existence of required var

## Get options, but with getopt, guess I don't need it
# args=`getopt -l help :detl: $*`
# for i in $args; do
#     case $i in
#     -d) echo "-p"
#         ;;
#     -e) shift;
#         optarg=$1;
#         echo "-q $optarg"
#         ;;
#     --help)
#         echo "--help"
#         ;;
#     esac
# done


if_trueuserdomains() {
    if [[ $use_trueuserdomains == "1" ]]; then
        domain_list=$(cut -d: -f1 /etc/trueuserdomains)
        debug "domain_list is ${domain_list}"
        mkdir $tmp_dir;
        for dom in $(cut -d: -f1 /etc/trueuserdomains); do
            dom_ip=127.0.0.1
            echo -e "$dom_ip\t\t$dom" >> /root/doms_to_add
        done
    fi
}

if_localdomains() {
    if [[ $use_localdomains == "1" ]]; then
        if [ ! -e /etc/localdomains ]; then
            echo -e "No /etc/localdomains file found.\nPlease try again"
            exit 0
        fi
        domain_list=$(cat /etc/localdomains)
        debug "domain_list is ${domain_list}"
        mkdir $tmp_dir;
        # this is cheating.  ill fix later
        for dom in $(cat /etc/localdomains); do
            dom_ip=$(\grep ^ip /var/cpanel/userdata/$(/scripts/whoowns $dom)/$dom | \cut -d: -f2 | \tr -d ' ')
            debug "$dom_ip\t$dom"
            echo -e "$dom_ip\t$dom" >> /root/doms_to_add
        done
    fi
}

if_local_resolution() {
    if [[ $local_resolution == "1" ]]; then

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
    if [[ $dns_resolution == "1" ]]; then
        main
    fi
}

main (){
    debug "Now in main.  domain_list is ${domain_list}"
    if [ ! -d $tmp_dir ]; then mkdir $tmp_dir; fi
    for i in $domain_list; do
        echo $i;
        curl --connect-timeout 1 $i | head -100 | lynx -stdin -dump | awk NF | head > $tmp_dir/$i;
    done;
    for i in $(\ls -A $tmp_dir/); do
        echo $i: ;
        cat $tmp_dir/$i ;
        echo;echo "============================";
    done > $summary_file

    # Cleanup
    echo -e "\nCleanup:"
    if [ -d $tmp_dir ]; then
        \rm -rvf $tmp_dir/*; \rmdir -v $tmp_dir
    else echo "Error: "$tmp_dir" doesn't exist."
    \rm -v /root/doms_to_add
    fi
}

# All done
print_complete() {
    echo -e "\nSite Check Complete.  Summary at:\n"$summary_file"\n"
}


# Run code
# wish I could put getopts in a function here, not sure why I can't
if_trueuserdomains
if_localdomains
if_local_resolution
if_dns_resolution
print_complete
