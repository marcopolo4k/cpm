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

function debug() {
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
	echo '-l use /etc/[L]ocaldomains (this is default for cPanel servers)'
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

# Get options (blatently stolen code from cpmig)
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

## Get options, but with getopt
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

main (){
    debug "Now in main.  domain_list is ${domain_list}"
    mkdir $tmp_dir;
    for i in $domain_list; do
        echo $i;
        curl $i | head -100 | lynx -stdin -dump | awk NF | head > $tmp_dir/$i;
    done;
    for i in $(\ls -A $tmp_dir/); do
        echo $i: ;
        cat $tmp_dir/$i ;
        echo;echo "============================";
    done > $summary_file


    if [ -d $tmp_dir ]; then
        rm -rvf $tmp_dir/*; rmdir -v $tmp_dir
    else echo "Error: "$tmp_dir" doesn't exist."
    fi
}

if [[ $use_trueuserdomains == "1" ]]; then
    domain_list=$(cut -d: -f1 /etc/trueuserdomains)
    debug "domain_list is ${domain_list}"
fi

if [[ $use_localdomains == "1" ]]; then
    domain_list=$(cat /etc/localdomains)
    debug "domain_list is ${domain_list}"
fi

if [[ $local_resolution == "1" ]]; then

    # Backup hosts file
    host_backup_file=/etc/hosts.cppremig.bk.$(date +%Y%m%d).$(date +%H).$(date +%M)
    debug "host_backup_file is ${host_backup_file}"
    cp -pv /etc/hosts $host_backup_file

    # Add files into /etc/hosts to ensure we only look at the locally hosted versions of the websites:
    for i in $(cut -d: -f1 /etc/trueuserdomains); do echo -e "127.0.0.1\t\t$i" >> /etc/hosts; done

    main

    # Cleanup
    cp -pv $host_backup_file /etc/hosts
    debug "host_backup_file is ${host_backup_file}"

fi


if [[ $dns_resolution == "1" ]]; then
    main
fi



# All done
echo -e "\nSite Check Complete.  Summary at:\n"$summary_file"\n"
