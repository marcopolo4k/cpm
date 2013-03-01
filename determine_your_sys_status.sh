#!/bin/bash
# This script checks for the Libkey compromise.  Commands mostly from:
# http://docs.cpanel.net/twiki/bin/view/AllDocumentation/CompSystem
#

# Establish colors
clroff="\033[0m";
red="\E[37;41m\033[4m";

num_fails=0
libkey_ver_check=$(\ls -la $(ldd $(which sshd) |grep libkey | cut -d" " -f3))
libkey_check_results=$(echo $libkey_ver_check | grep 1.9)
if [ "$libkey_check_results" ]; then
    echo -e $red"libkey check failed. version: \n"$libkey_ver_check$clroff;
    num_fails=$((num_fails+1))
fi
libkey_dir=$(echo $libkey_ver_check | cut -d"/" -f2)
libkey_ver=$(echo $libkey_ver_check |grep libkey | awk '{print $NF}')
thelibkey=$(echo "/"$libkey_dir"/"$libkey_ver)
assiciated_rpm=$(rpm -qf $thelibkey)
assiciated_rpm_check=$(echo $assiciated_rpm | grep "is not owned by any package")
if [ "$assiciated_rpm_check" ]; then
    echo -e $red"libkey check failed. rpm associated with libkey file: "$clroff
    num_fails=$((num_fails+1))
fi

# Command 1
keyu_pckg_chg_test=$(rpm -V keyutils-libs)
if [ "$keyu_pckg_chg_test" ]; then
    echo -e $red"Cmd1: keyutils-libs check failed. The rpm shows the following file changes: "$clroff
    echo $keyu_pckg_chg_test
    num_fails=$((num_fails+1))
fi

# Command 2
cmd_2_chk=$(\ls -la $thelibkey | egrep "so.1.9|so.1.3.2|1.2.so.2");
if [ "$cmd_2_chk" ]; then
    echo -e $red"Cmd2: Known bad package check failed. The following file is linked to libkeyutils.so.1: "$clroff
    echo $cmd_2_chk
    num_fails=$((num_fails+1))
fi

# Command 3
cmd_3_chk=$(strings $thelibkey | egrep 'connect|socket|inet_ntoa|gethostbyname')
if [ "$cmd_3_chk" ]; then
    echo -e $red"Cmd3: libkeyutils libraries contain networking tools: "$clroff
    echo $cmd_3_chk
    num_fails=$((num_fails+1))
fi

# Command 4
check_ipcs_lk=$(for i in `ipcs -mp | grep -v cpid | awk {'print $3'} | uniq`; do ps aux | grep $i | grep -v grep;done | grep -i ssh)
if [ "$check_ipcs_lk" ];
 then echo -e $red"Cmd4: IPCS Check failed.  Doesn't necessarily mean anything:\n"$clroff$check_ipcs_lk;
 num_fails=$((num_fails+1))
fi

# Command 6
for i in $(ldd /usr/sbin/sshd | cut -d" " -f3); do
 sshd_library=$(rpm -qf $i);
 if [ ! "sshd_library" ]; then
  echo -e "\nCmd 6: "$i" has no associated library."; echo $sshd_library;
  num_fails=$((num_fails+1))
 fi;
done

if [ "$num_fails" -gt 0 ]; then
 for i in $(\ls /lib*/libkeyutils*); do
  cmd_3_chk=$(strings $i | egrep 'connect|socket|inet_ntoa|gethostbyname');
  if [ "$cmd_3_chk" ]; then
      stat $i | grep -i change;
  fi;
 done
fi

# Just for info:
echo $assiciated_rpm
