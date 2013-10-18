#!/bin/bash
# Version 2: only print at the end
# 
# This script checks for the Libkey compromise.  6 Commands are from:
# http://docs.cpanel.net/twiki/bin/view/AllDocumentation/CompSystem
#
# How to run this script:
# curl -s --insecure https://raw.github.com/cPMarco/cpm/master/libkey_check.sh | sh
#

# Only print debugging messages if, well, debugging

debug() {
	debug="off"
	if [ "$debug" = "on" ]; then
		echo $1
	fi
}

# Establish colors
clroff="\033[0m";
red="\E[37;41m\033[4m";

# Get options
silent=0
verbose=0
while getopts ":s:v" opt; do
	case $opt in
        s) silent="1";;
        v) verbose="1";;
        # h) print_help;;
        \?) echo "invalid option: -$OPTARG"; echo; # print_help;;
        #:) echo "option -$OPTARG requires an argument."; echo; print_help;;
    esac
done

# At the end, we'll show how many checks failed.
num_fails=0

# Code starts here
print_header() {
	echo -e "\nSearching for Libkey compromise. The '6 commands' are described here:\n
http://docs.cpanel.net/twiki/bin/view/AllDocumentation/CompSystem"
}

# These general checks are not the 6 commands listed on the website
libkey_version_check() {
	libkey_ver_check=$(\ls -la $(ldd $(which sshd) |grep libkey | cut -d" " -f3))
	#todo: length_check $libkey_ver_check
	libkey_check_results=$(echo $libkey_ver_check | egrep "1.9|1.3.2|1.3.0|1.2.so.2|1.2.so.0")
}
 
is_rpm_owned() {
	libkey_dir=$(echo $libkey_ver_check | cut -d"/" -f2)
	libkey_ver=$(echo $libkey_ver_check |grep libkey | awk '{print $NF}')
	thelibkey=$(echo "/"$libkey_dir"/"$libkey_ver)
	assiciated_rpm=$(rpm -qf $thelibkey)
	 
	assiciated_rpm_check=$(echo $assiciated_rpm | grep "is not owned by any package")
	debug "the libkey is: ${thelibkey}"
}

# this will take too long:
# "The RPMs contain 3-digit release numbers to prevent updates from overwriting them"
# 3dig_release=$(rpm -qa | grep -i ssh | egrep "p[0-9]-[0-9]{3}\.")
# checkfor "$3dig_release" "SSH RPM's with 3-digit release numbers found:"


# Here the 6 commands listed on the website 
command_1() {
	cmd_1_chk=$(rpm -V keyutils-libs | egrep -v "\.[M\.]\.\.\.\.\.[T\.]\.")
}

command_2() {
	cmd_2_chk=$(\ls -la $thelibkey | egrep "so.1.9|so.1.3.2|1.2.so.2");
}

command_3() {
	cmd_3_chk=$(strings $thelibkey | egrep 'connect|socket|inet_ntoa|gethostbyname')
}

command_4() {
	check_ipcs_lk=$(for i in `ipcs -mp | grep -v cpid | awk {'print $3'} | uniq`; do ps aux | grep '\b'$i'\b' | grep -v grep;done | grep -i ssh)
}

#placeholder for:
#function command_5() {
#}

command_6() {
	cmd6fail=0
	for i in $(ldd /usr/sbin/sshd | cut -d" " -f3); do
		sshd_library=$(rpm -qf $i);
		if [ ! "$sshd_library" ]; then
			cmd6fail=$((cmd6fail+1))
		fi;
	done
	if [ "$cmd6fail" -gt 0 ]; then
		num_fails=$((num_fails+1))
	fi
}


add_results() {
	if [ "$libkey_check_results" ]; then num_fails=$((num_fails+1)); fi;
	if [ "$assiciated_rpm_check" ]; then num_fails=$((num_fails+1)); fi;
	if [ "$cmd_1_chk" ]; then num_fails=$((num_fails+1)); fi;
	if [ "$cmd_2_chk" ]; then num_fails=$((num_fails+1)); fi;
	if [ "$cmd_3_chk" ]; then num_fails=$((num_fails+1)); fi;
	if [ "$cmd_4_chk" ]; then num_fails=$((num_fails+1)); fi;
	if [ "$cmd_5_chk" ]; then num_fails=$((num_fails+1)); fi;
	if [ "$cmd_6_chk" ]; then num_fails=$((num_fails+1)); fi;
	#num_fails=$((num_fails+1));
}

print_results() {
#debug "print_results is getting run"
	if [ $num_fails -gt 0 -o $verbose -eq "1" ]; then
		print_header
		#debug "num fails is ${num_fails}"
 
		if [ "$libkey_check_results" ]; then 
			echo -e "\n"$red"libkey check failed due to version number: "$clroff"\n$libkey_check_results";
		#don't think i need this:
		#else echo -e "Version number:\nPassed.\n"
		fi

		if [ "$assiciated_rpm_check" ]; then
			echo -e "\n"$red"libkey check failed due to associated RPM:"$clroff"\n"$assiciated_rpm
		else
			echo -e "\nRPM associated with libkey file:\n"$assiciated_rpm
		fi

		echo -e "\nCommand 1 Test:"
		if [ "$cmd_1_chk" ]; then
			echo -e $red"keyutils-libs check failed. The rpm shows the following file changes: "$clroff;
			echo -e "# rpm -V keyutils-libs";
			echo -e "$cmd_1_chk\n\n If the above changes are any of the following, then maybe it's ok (probable false positive - you could ask the sysadmin what actions may have caused these):
 .M.....T
 However, if changes are any of the following, then it's definitely suspicious:
 S.5.L...
 see 'man rpm' and look for 'Each of the 8 characters'"
		else echo -e "Passed."
		fi

		echo -e "\nCommand 2 Test:"
		if [ "$cmd_2_chk" ]; then
			echo -e $red"Known bad package check failed. The following file is linked to libkeyutils.so.1: "$clroff"\n"
			echo -e $cmd_2_chk
		else echo -e "Passed."
		fi

		echo -e "\nCommand 3 Test:"
		if [ "$cmd_3_chk" ]; then
			echo -e "\n"$red"libkeyutils libraries contain networking tools: "$clroff"\n"
			echo -e $cmd_3_chk"\n";
		else echo -e "Passed."
		fi

		echo -e "\nCommand 4 Test:"
		if [ "$check_ipcs_lk" ]; then
			echo -e "\n"$red"IPCS Check failed.  This is sometimes a false positive:"$clroff"\n"
			echo -e $check_ipcs_lk"\n";
		else echo -e "Passed."
		fi

		echo -e "\nCommand 5 Test is not designed to run by this automated script"

		echo -e "\nCommand 6 Test:"
		cmd6fail=0
		for i in $(ldd /usr/sbin/sshd | cut -d" " -f3); do
			sshd_library=$(rpm -qf $i);
			if [ ! "$sshd_library" ]; then
				echo -e "\n"$i" has no associated library."; echo $sshd_library;
				cmd6fail=$((cmd6fail+1))
			fi;
		done
		if [ "$cmd6fail" -gt 0 ]; then
			num_fails=$((num_fails+1))
		else echo "Passed."
		fi

fi
}

# Print Summary and show the dates on the files
summary_of_fail() {
	if [ "$num_fails" -gt 0 ]; then
		echo -e "\nPossible change times of the compromised files:"
		for i in $(\ls /lib*/libkeyutils*); do
			cmd_3_chk=$(strings $i | egrep 'connect|socket|inet_ntoa|gethostbyname');
			if [ "$cmd_3_chk" ]; then
				stat $i | grep -i change;
			fi;
		done
		debug "the libkey is: ${thelibkey}"
		stat $thelibkey | grep -i change
		echo -e "\nTotal Number of checks failed: "$num_fails" (out of 7 checks currently)\n\n
Based on what I've seen so far, the following might be a general guide to interpret results:
1 check failed = probably false positive. This is usually commands 1, 4, or 6
2 checks failed = somewhat likely real
3+ checks failed = definitely real\n"
	fi
	echo "Single security check complete"
}

# Run all functions
#general_checks
libkey_version_check
is_rpm_owned
command_1
command_2
command_3
command_4
#placeholder: command_5
command_6
add_results
print_results
summary_of_fail
