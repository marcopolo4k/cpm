#!/bin/bash
# This script checks for the Libkey compromise.  6 Commands are from:
# http://docs.cpanel.net/twiki/bin/view/AllDocumentation/CompSystem
#
# Moved to:
# https://github.com/cPMarco/cpm/blob/master/libkey_check.sh
echo -e "New script location:\nsh <(curl -s --insecure https://raw.github.com/cPMarco/cpm/master/libkey_check.sh) -v";


## How to run this script:
## curl -s --insecure https://raw.github.com/cPMarco/cpm/master/determine_your_sys_status.sh | sh
##
## Todo: non-verbose mode
#
## Establish colors
#clroff="\033[0m";
#red="\E[37;41m\033[4m";
#
## At the end, we'll show how many checks failed.
#num_fails=0
#
## Standard error check:
## If an error check variable is not empty, then it failed the check, so describe 
## what the error is in red, then the results of the check.  Optional 2nd error msg
## afterwards as well.
#function checkfor() {
# if [ "$1" ];
#  then echo -e $red"$2"$clroff"\n$1\n$3";
#  num_fails=$((num_fails+1))
#  else echo "Passed."
# fi
#}
#
#
## Code starts here
#function print_header() {
# echo -e "\nSearching for Libkey compromise. The '6 commands' are described here:\n
#http://docs.cpanel.net/twiki/bin/view/AllDocumentation/CompSystem"
#}
#
## These general checks are not the 6 commands listed on the website
#function general_checks() {
# echo -e "\nFirst general checks:" 
# libkey_ver_check=$(\ls -la $(ldd $(which sshd) |grep libkey | cut -d" " -f3))
# #length_check $libkey_ver_check
# libkey_check_results=$(echo $libkey_ver_check | egrep "1.9|1.3.2|1.3.0|1.2.so.2|1.2.so.0")
# checkfor "$libkey_check_results" "libkey check failed due to version number: "
# 
# libkey_dir=$(echo $libkey_ver_check | cut -d"/" -f2)
# libkey_ver=$(echo $libkey_ver_check |grep libkey | awk '{print $NF}')
# thelibkey=$(echo "/"$libkey_dir"/"$libkey_ver)
# assiciated_rpm=$(rpm -qf $thelibkey)
# 
# assiciated_rpm_check=$(echo $assiciated_rpm | grep "is not owned by any package")
# if [ "$assiciated_rpm_check" ]; then
#  echo -e $red"libkey check failed due to associated RPM:"$clroff"\n"$assiciated_rpm
#  num_fails=$((num_fails+1))
# else
#  echo -e "RPM associated with libkey file:\n"$assiciated_rpm
#  echo "Passed."
# fi
#}
#
## this will take too long:
## "The RPMs contain 3-digit release numbers to prevent updates from overwriting them"
## 3dig_release=$(rpm -qa | grep -i ssh | egrep "p[0-9]-[0-9]{3}\.")
## checkfor "$3dig_release" "SSH RPM's with 3-digit release numbers found:"
#
#
## Here the 6 commands listed on the website 
#function command_1() {
# echo -e "\nCommand 1 Test:"
# keyu_pckg_chg_test=$(rpm -V keyutils-libs | egrep -v "\.[M\.]\.\.\.\.\.[T\.]\.")
# checkfor "$keyu_pckg_chg_test" "keyutils-libs check failed. The rpm shows the following file changes: " "\n If the above changes are any of the 
#following, then maybe it's ok (probable false positive - you could ask the sysadmin what actions may have caused these):
# .M.....T
# However, if changes are any of the following, then it's definitely suspicious:
# S.5.L...
# see 'man rpm' and look for 'Each of the 8 characters'"
#}
#
#function command_2() {
# echo -e "\nCommand 2 Test:"
# cmd_2_chk=$(\ls -la $thelibkey | egrep "so.1.9|so.1.3.2|1.2.so.2");
# checkfor "$cmd_2_chk" "Known bad package check failed. The following file is linked to libkeyutils.so.1: "
#}
#
#function command_3() {
# echo -e "\nCommand 3 Test:"
# cmd_3_chk=$(strings $thelibkey | egrep 'connect|socket|inet_ntoa|gethostbyname')
# checkfor "$cmd_3_chk" "libkeyutils libraries contain networking tools: "
#}
#
#function command_4() {
# echo -e "\nCommand 4 Test:"
# check_ipcs_lk=$(for i in `ipcs -mp | grep -v cpid | awk {'print $3'} | uniq`; do ps aux | grep '\b'$i'\b' | grep -v grep;done | grep -i ssh)
# checkfor "$check_ipcs_lk" "IPCS Check failed.  This is sometimes a false positive:"
#}
#
#function command_5() {
# echo -e "\nCommand 5 Test is not designed to run by this automated script"
#}
#
#function command_6() {
# echo -e "\nCommand 6 Test:"
# cmd6fail=0
# for i in $(ldd /usr/sbin/sshd | cut -d" " -f3); do
#  sshd_library=$(rpm -qf $i);
#  if [ ! "$sshd_library" ]; then
#   echo -e "\n"$i" has no associated library."; echo $sshd_library;
#   cmd6fail=$((cmd6fail+1))
#  fi;
# done
# if [ "$cmd6fail" -gt 0 ]; then
#  num_fails=$((num_fails+1))
# else echo "Passed."
# fi
#}
#
#
## Print Summary and show the dates on the files
#function summary() {
# if [ "$num_fails" -gt 0 ]; then
#  echo -e "\nPossible change times of the compromised files:"
#  for i in $(\ls /lib*/libkeyutils*); do
#   cmd_3_chk=$(strings $i | egrep 'connect|socket|inet_ntoa|gethostbyname');
#   if [ "$cmd_3_chk" ]; then
#    stat $i | grep -i change;
#   fi;
#  done
#  echo -e "\nTotal Number of checks failed: "$num_fails" (out of 7 checks currently)\n\n
#Based on what I've seen so far, the following might be a general guide to interpret results:
#1 check failed = possibly false positive. This is usually command 4 or 6
#2 checks failed = very likely real
#3+ checks failed = definitely real"
# fi
# 
# echo
#}
#
## Run all functions
#print_header
#general_checks
#command_1
#command_2
#command_3
#command_4
#command_5
#command_6
#summary
