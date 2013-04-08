# Auto-checks by cPanel Marco
# These are some quick checks for a variety of settings and configurations
# No configuration files are changed or saved in this script
# One way to run this script:
# curl -O https://raw.github.com/cPMarco/cpm/master/autochecks.sh > autochecks.sh; chmod u+x autochecks.sh
# ./autochecks.sh

# todo:
# check for /var/cpanel/use_old_easyapache 

# Establish colors (White for heading, red for errors)
white="\E[37;44m\033[7m";
clroff="\033[0m";
red="\E[37;41m\033[4m";


# Implemented late, but I do this now.
# If an error that returns positive, print the error in red first, then the results
function checkfor() { 
if [ "$1" ];
 then echo -e $red"$2"$clroff; echo "$1";
fi
}

# Get cPanel Version
version=$(/usr/local/cpanel/cpanel -V)
major=$(echo $version | cut -d. -f1)
minor=$(echo $version | cut -d. -f2)


echo -e $white"Some quick checks by cPanel Analyst:"$clroff;

h=`hostname -i`;
#ticket_info_var=$PROMPT_COMMAND
#echo "Ticket Info: "$ticket_info_var
#echo $ticket_info_var
#PROMPT_COMMAND='echo -ne "\033]0;${h}: ${PWD}\007"' ;

export PS1="[\[\e[4;32m\]\u@\h \w\[\e[0m\]]# ";

# is this dot really important? it breaks mysqlerr later
hn=$(hostname) ;
hip=$(dig +short $hn);
if [ "$hip" ];
 then hrip=$(dig +short -x $hip | sed 's/\.$//');
 if [ "$hn" == "$hrip" ];
  then echo ;
  else echo -e $red"Reverse DNS: "$clroff$hn" != "$hrip;
 fi;
 else echo -e $red"Hostname not resolvable"$clroff;
fi;

echo -ne $hn": "$h"\n";
/usr/local/cpanel/cpanel -V;
echo

# Look for Cloudlinux
cl_check=$(lsmod|grep lve; uname -a|grep -o lve;);
if [ "cl_check" ]; then
    echo $cl_check;
fi
echo;

# Hardware checks
curl -s https://raw.github.com/cPMarco/cpm/master/hardware_checks.sh | sh

echo -e "\nCluster Function, Status:";
if [ -e /var/cpanel/cluster/root/config ];
 then cl='/var/cpanel/cluster/root/config';
 for i in `\ls $cl | grep dnsrole`;
  do echo -n $i": ";
  cat $cl/$i;
  clip=/var/cpanel/clusterqueue/status/$(echo $i|cut -d"-" -f1);
  echo -n ", status: ";
  if [ -e $clip ];
   then cat $clip;
   else echo NA;
  fi;
 done;
 else echo "no cluster files";
fi;
echo;


hta=$(\ls / /home | grep htaccess);
echo -e $red$hta$clroff;

# Checkservd log
# https://staffwiki.cpanel.net/LinuxSupport/OneLiners#Show_chksrvd_failures
echo -e "\nRecent chksrvd errors:";
echo -n "starting search at: ";  tail -3200 /var/log/chkservd.log | awk '{if ($1~/\[20/) print $1,$2,$3}' | head -1
every_n_min=10; tail -3200 /var/log/chkservd.log |awk -v n=$every_n_min '{if ($1~/\[20/) lastdate=$1" "$2" "$3; split($2,curdate,":"); dmin=(curdate[2]-lastmin); dhr=(curdate[1]-lasthr); if ($0!~/Restarting|nable|\*\*|imeout|ailure|terrupt/ && $0~/:-]/) print lastdate"....."; for (i=1;i<=NF;i=i+1) if ($i~/Restarting|nable|\*\*|imeout|ailure|terrupt|100%|9[89]%|second/) if ($1~/\[20/) print $1,$2,$3,$(i-1),$i,$(i+1); else print lastdate,$(i-1),$i,$(i+1); if($1~/\[20/ && (lastmin!=0 || lasthr!=0) && (dmin>n || (dhr==1 && (dmin>-(60-n))) || dhr>1 )) print $1,$2,$3" check took longer than "n" minutes. (hr:min): "dhr":"dmin; if ($1~/\[20/) {lastmin=curdate[2]; lasthr=curdate[1]} }'
echo "Current time: "; date

# this section is repeated in rc.remote.  #todo: fix that.
a='/usr/local/apache';
conf=$a/conf/httpd.conf;
c='/usr/local/cpanel';
ea='/usr/local/cpanel/logs/easy/apache';
hn=$(hostname);
alias lf='echo `\ls -lrt|\tail -1|awk "{print \\$9}"`';

# I removed the aliases, trying to keep one location.  still ugly.

# Temporary checks
echo;
unamefail=`egrep "^USER" /var/cpanel/users/* | egrep "/.*\..*"`;
echo -e $red$unamefail$clroff;

# I should add this to chksrvd, as I found it on 130123 in 3665403
spamd_fail_chksrvd=$(tail -1200 /var/log/chkservd.log |grep 'spamd \[Service' |awk '{print $1,$2,$3}');
if [ "$spamd_fail_chksrvd" ];
 then echo -e $red"Spamd error in chksrvd:"$clroff"\n"$spamd_fail_chksrvd;
fi;

rooterror=$(tail -1000 /usr/local/cpanel/logs/error_log|egrep "Illegal instruction|root' is empty or non-existent"|egrep "2012-0[89]");
echo -e $red$rooterror$clroff;

#egrep -i "Illegal instruction|Undefined subroutine" /var/cpanel/updatelogs/*
# Error downloading, see ticket 3900473
cd /var/cpanel/updatelogs/; for i in $(ls -rt | tail -3); do egrep -i "Illegal instruction|Undefined subroutine|Error downloading" $i; done
#egrep -i "Illegal instruction|Undefined subroutine" /usr/local/cpanel/logs/easy/apache/*
cd /usr/local/cpanel/logs/easy/apache; for i in $(ls -rt | tail -5); do egrep -i "Illegal instruction|Undefined subroutine" $i; done
badrepo=$(egrep "alt\.ru|ksplice-up" /etc/yum.repos.d/*);
echo -e $red$badrepo$clroff;

backup_log_dir='/usr/local/cpanel/logs/cpbackup';
if [ -d "$backup_log_dir" ]; then
 cd $backup_log_dir;
 backup_interrupted=$(lf | xargs grep EOF | tail -3;)
 checkfor "$backup_interrupted" "Backup errors that could be a HD issue (full/bad):"
 cd ~;
 else
  echo -e $red"No backup log dir"$clroff;
  echo -n "Are account backups on? ";
  grep BACKUPACCTS /etc/cpbackup.conf | cut -d" " -f2;
fi;

cd $ea;
eafail1=$(for i in $(\ls); do tail -3 $i; done | grep -i "Failed");
cd ~;
if [ "$eafail1" ];
 then echo -e $red"Recent EasyApache failure:"$clroff"\n"$eafail1;
fi #FB 60087 says if egrep is a link theres a prob, but havent seen in forever, can ignore

rcbug=$(ps auxfwww | grep template.sto[r]);
echo -e $red$rcbug$clroff; #FB62001

relayservers=$(head /etc/relayhosts)
if [ "$relayservers" ];
 then echo -e "Relay Servers in /etc/relayhosts:\n"$relayservers"..."
fi

fb63493=$(ps aux | grep -i postfi[x])
checkfor "$fb63493" "Postfix processes are running (See FB 63493):"

# ************
# Perl Checks for pre-11.36
# ************
if [ $minor -lt 36 ]; then
 echo -e "This system has not been upgraded to 11.36 yet, so running some perl & yum.conf checks:\n"

 curl https://raw.github.com/cPMarco/cpm/master/check_system_perl.sh | sh

 # FB 63294
 for ex_in_list in apache bind-chroot courier dovecot exim filesystem httpd mod_ssl mydns mysql nsd perl php proftpd pure-ftpd ruby spamassassin squirrelmail; do
  ex_in_conf=$(egrep -i "exclude=.*$ex_in_list" /etc/yum.conf|egrep -v "#.*$ex_in_list");
  if [ ! "$ex_in_conf" ]; then
   echo -e $red"$ex_in_list is missing from /etc/yum.conf excludes (FB 63294)"$clroff;
  fi;
 done
fi

echo "Perl checks for all versions of cPanel:"
perl -V:installsitearch
perl -V:installsitelib
perl -V:installvendorarch
perl -V:installvendorlib
perl -v | head -2 | awk NF; which perl; echo

# FB 63311
num_exclude_lines=$(grep -i exclude /etc/yum.conf|egrep -vi "#.*exclude" | wc -l)
if [ "$num_exclude_lines" -gt 1 ];
 then echo -e $red"There should only be 1 exclude line in /etc/yum.conf, but there's "$num_exclude_lines". (FB 63311)"$clroff;
fi

postfx_error=$(lsof -i :25 | awk '/localhost:smtp/ {print $2}')
if [ "$postfix_error" ]; then echo -e $red$postfix_error"\n\n see tristan email, FB 63493"$clroff; fi

fb63493=$(ps aux | grep -i postfi[x])
if [ "$fb63493" ];
 then echo -e "Postfix processes are running:\n"$fb63493"\nSee FB 63493"
fi

fb64265=$(\ls /root/perl5)
checkfor "$fb63493" "See FB 64265:"

# prompt to clean up any test email account on this server
if [ -e /root/cptestm/ ] && [ ! -e /root/cptestm/.login* ]; then
#    old_test_email=$(grep cptestm /home/*/etc/*/passwd)
#    checkfor "$old_test_email" "Cruft test email account:"
    echo "Found cruft test email account. Probably removed it on this date." > /root/cptestm/.login.log.$(date +%Y%m%d%H%M%S)
    echo -e "Possibly a cruft test email account:\n grep cptestm /home/*/etc/*/passwd"
fi
