#!/bin/sh
# This script shows some useful DNS information. It's to be run on the problem cPanel server.
# The one argument is the domain having problems.
#
# How to run:
# curl -s https://raw.githubusercontent.com/cPMarco/cpm/master/dnscheck.sh > dnscheck.sh; sh dnscheck.sh cpanel.net
#
# Todo: show digs locally, authdns servers, and their default dns servers
#


# Check for dig commannd
verify_tools() {
    command -v dig >/dev/null 2>&1 || { echo >&2 "Oops! The dig command is necessary for this script, but was not found on this system :(  Aborting."; exit 1; }
}

# Check input
check_input() {
    if [ -z ${dom} ]; then
        echo 'Please specify a domain.'; exit 1;
    fi
}

# Get input, initial variables
dom=${1}
tld=${dom#*.}
options="+noall +authority +additional +comments"

# Functions
create_dig_oneliner() {
	tld_server=`dig NS ${tld}. +short | head -n1`
	dig_oneliner="dig @${tld_server} ${dom}. ${options}"
}

get_result() {
	dig_result=`${dig_oneliner}`
}

set_colors() {
    # Colors and formatting
    greenbold='\033[1;32m'
    clroff="\033[0m";
}

get_nameservers() {
	# nameserver names and possibly IP's from TLD servers
	auth_ns=`${dig_oneliner} | awk '/AUTHORITY SECTION/,/^[ ]*$/' | awk '{print $NF}' | sed -e 1d -e 's/.$//'`
	additional_ips=`${dig_oneliner} | awk '/ADDITIONAL SECTION/,0' | awk '{print $NF}' | sed 1d`
}

get_nameserver_ips() {
	# get bare IP's of nameservers
	if [ "$additional_ips" ];
		then bare_result=$additional_ips;
		else bare_result=`
			for auth_ips in "${auth_ns[@]}"; do
				dig +short $auth_ips
				echo "(Warning: these IP's had to be resolved manually, so glue records are bad)"
			done;`
	fi;
}

print_results() {
    printf "%b\n" "${greenbold}\nAuthoritative Nameserver IPs:\n${clroff}${bare_result}\n"
}



# These find Authoritative DNS:
verify_tools
check_input
create_dig_oneliner
get_result
set_colors
get_nameservers
get_nameserver_ips
print_results

# search named.conf for the domain
printf "%b\n" "${greenbold}/etc/named.conf:${clroff}"
egrep "ternal\" {|$dom" /etc/named.conf

# the hosts line in nsswitch should look like this:
# hosts:      files dns
grep hosts /etc/nsswitch.conf

# show resolv file. 
printf "%b\n" "${greenbold}\n\n/etc/resolv.conf:${clroff}"
cat /etc/resolv.conf

# show hosts file. localhost should only be on 127, the hostname should be listed once, etc.
printf "%b\n" "${greenbold}\n\n/etc/hosts:${clroff}"
cat /etc/hosts
echo
