#/bin/sh
# bash script to verify system perl location is correct
# does not work for cpanel perl rpm yet
# http://staffwiki.cpanel.net/LinuxSupport/PerlIssues

# Colors and formatting
greenbold='\033[1;32m'
clroff="\033[0m";
redbold='\033[1;31m'


serverenv=$(strings -1 /var/cpanel/envtype)

echo "cPanel claims this server is a $serverenv server, so we'll test it as such."


# set the two link vars.  if they are links, these vars will be full

ubp="$(readlink /usr/bin/perl)"
ulbp="$(readlink /usr/local/bin/perl)"
verdict=1

if [ $serverenv = "standard" ]; then

 if [ $ubp ]; then
  echo "/usr/bin/perl is a link to $ubp. This is not correct. Just to check, here it is:";
  ls -la /usr/bin/perl;
  verdict=2;
 fi
 
 if [ ! $ulbp ]; then
  echo "/usr/local/bin/perl is not a link. This is not correct. Just to check, here it is:";
  ls -la /usr/local/bin/perl;
  verdict=2;
 fi
 
 if [[ ! $(perl -v | grep thread) ]];
  then echo "System perl is not threaded.  This is not correct";
  verdict=2;
 fi

elif [ $serverenv ]; then

 if [ ! $ubp ]; then
  echo "/usr/bin/perl is not a link. This is not correct.  Just to check, here it is:";
  ls -la /usr/bin/perl;
  verdict=2;
 fi
 
 if [ $ulbp ]; then
  echo "/usr/local/bin/perl is a link. This is not correct. Just to check, here it is:";
  ls -la /usr/local/bin/perl;
  verdict=2;
 fi
 
 if [[ $(perl -v | grep thread) ]]; then
  echo "System perl is threaded.  This is not correct.";
  verdict=2;
 fi

else

 echo "There was a problem determining server environment.  You can try installing & running 'virt-what'.  Also, please let Marco know."
 verdict=2;

fi

if [ $verdict == 1 ]; then
 printf "%b\n" "${greenbold}PASS${clroff}: The system perl appears to be set correctly.";
else
 printf "%b\n" "${redbold}FAIL${clroff}: The system perl appears incorrect."
fi
