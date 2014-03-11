# Auto-checks by cPanel Marco
# These are some quick checks for a variety of settings and configurations
# No configuration files are changed or saved in this script
# One way to run this script:
# source /dev/stdin <<< "$(curl -sL https://raw.github.com/cPMarco/cpm/master/autochecks.sh)"

# todo:
# check for /var/cpanel/use_old_easyapache 


c=/usr/local/cpanel; v=/var/cpanel; a=/usr/local/apache; 
ea=$c/logs/easy/apache; conf=$a/conf/httpd.conf; ul=$v/updatelogs;
hn=$(hostname); hip=$(dig +short $hn); 
h=$(history | awk '/cPTKT [0-9]/ {print $5,$6,$7,$8}' | tail -1)" - "$hip;PROMPT_COMMAND='echo -ne "\033]0;${h}\007"';

# Linux aliases
alias diff='diff -y --suppress-common-lines'; alias less='\less -IR'; alias grep='grep --color'
alias ls='\ls -F --color'; alias lsd='ls | grep \/$'; alias lsdl='ls -lrth | grep ^d'; alias lsp='ls -d -1 $PWD/**';
alias lf='echo `\ls -lrt|\tail -1|awk "{print \\$9}"`'; alias lf2='echo `\ls -lrt|\tail -2|awk "{print \\$9}"|head -1`';
alias perms=awk\ \'BEGIN\{dir\=DIR?DIR:ENVIRON[\"PWD\"]\;l=split\(dir\,parts,\"/\"\)\;last=\"\"\;for\(i=1\;i\<l+1\;i++\)\{d=last\"/\"parts\[i\]\;gsub\(\"//\",\"/\",d\)\;system\(\"stat\ --printf\ \\\"%a\\\t%u\\\t%g\\\t\\\"\ \\\"\"d\"\\\"\;\ echo\ -n\ \\\"\ \\\"\;ls\ -ld\ \\\"\"d\"\\\"\"\)\;last=d\}\}\'

alias ifm='ifconfig |egrep -o "venet...|lo|eth[^ ]*|ppp|:(.{1,3}\.){3}.{1,3}"|grep -v 255|uniq';
alias ips=$(ifconfig | awk '/inet/ {if ($2!~/127.0|:$/) print $2}' | awk -F: '{print "echo "$2}');
alias localips='ips';
function mysqlerr() {
    custom_mysql_log=$(\grep '^log-error' /etc/my.cnf | cut -d= -f2);
    if [ "$custom_mysql_log" ];
        then date; echo $custom_mysql_log; less -I $custom_mysql_log;
    else date; echo /var/lib/mysql/$hn.err; less -I /var/lib/mysql/$hn.err
    fi
}
alias ssl='openssl x509 -noout -text -in';
function cpbak() { cp -v $@ $@.cpbak.$(date +%Y%m%d).$(date +%H).$(date +%M);}

# cPanel aliases
alias vhost='grep -B1 "Name $dom" $conf|head -1; perl -ne "print if /$dom/ .. /Host>$/" $conf; echo "Curl: "; curl $dom | head'
alias ealogs=$(\ls -lrt $ea | awk -v p=$ea '{if ($5>5000) print "ls -lah "p"/"$NF}'); alias ealog=ealogs;
alias eapre='curl https://raw.github.com/cPanelTechs/TechScripts/master/ea-precheck.sh | sh'
alias ssl='openssl x509 -noout -text -in'; \grep --color github /etc/hosts;
function sslshort() { openssl x509 -noout -text -in "$1" | egrep "Issuer|Subject:|^[ ]*Not"; }
alias sfiles='grep "\"/" /root/cptestm/strace.cpsrvd | cut -d"\"" -f2 | egrep -v "000|<|---|::|.pm$|.pmc$|.so(.?)*$|.bs$|\.py$|\.pyc" | uniq | less -I'
alias rp='$c/bin/rebuild_phpconf --current'

function cpm() { curl -s --insecure https://raw.github.com/cPMarco/cpm/master/$1 | bash /dev/stdin '$2'; }
mkdir /root/cptestm/

# No longer used:
# Save example user/domain as variables:
#dom= ; if (echo $dom|egrep "\.") then u=$(/scripts/whoowns $dom); else tmp=$(egrep " $dom$" /etc/trueuserdomains|cut -d: -f1); u=$dom; dom=$tmp;fi; uhome=$(egrep "^$u:" /etc/passwd|cut -d":" -f6); www=$uhome/public_html/ ; echo -e "\n"$dom"\n"$u"\n"$www"\n"; fgrep -i spended /var/cpanel/users/$u; egrep "limit.*1$" /var/cpanel/users/$u; ssl=$uhome/ssl



# Establish colors (White for heading, red for errors)
white="\E[37;44m\033[7m";
clroff="\033[0m";
red="\E[37;41m\033[4m";


# Implemented late, but I do this now.
# If an error that returns positive, print the error in red first, then the results
function checkfor() { 
if [ "$1" ];
 then echo -e $red"$2"$clroff"\n$1\n$3";
fi
}

# Get cPanel Version
version=$(/usr/local/cpanel/cpanel -V)
major=$(echo $version | cut -d. -f1)
minor=$(echo $version | cut -d. -f2)


echo -e $white"Some quick checks by cPanel Analyst:"$clroff;
h=`hostname -i`;

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

# Does this server actually controls it's own Reverse DNS?
rvs_is_local=$(ifconfig |egrep -o "venet...|lo|eth[^ ]*|ppp|:(.{1,3}\.){3}.{1,3}"|grep -v 255|uniq | grep $(dig +short $(dig $(echo $hip | awk -F . '{print $4"."$3"."$2"."$1}').in-addr.arpa. | grep SOA | awk '{print $5}')) 2>/dev/null )
checkfor "$rvs_is_local" "This server actually controls it's own Reverse DNS:" "dig \$(echo $hip | awk -F . '{print \$4\".\"\$3\".\"\$2\".\"\$1}').in-addr.arpa. | grep SOA"

echo -ne $hn": "$h"\n";
/usr/local/cpanel/cpanel -V;
echo

# Look for Cloudlinux
#todo: fix this, which happened once:
# lsmod|grep lve
#dns_resolver            5463  1 cifs
cl_check=$(lsmod|grep lve; uname -a|grep -o lve;);
if [ "cl_check" ]; then
    echo $cl_check;
fi
echo;

# Hardware checks
curl -s https://raw.github.com/cPMarco/cpm/master/hardware_checks.sh | sh

# Single Security Check
curl -s https://raw.github.com/cPMarco/cpm/master/libkey_check.sh | sh

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
checkfor "$hta" "Global? htaccess file in home" "This is sometimes associated with hacks"

# Checkservd log
# https://staffwiki.cpanel.net/LinuxSupport/OneLiners#Show_chksrvd_failures
echo -e "\nRecent chksrvd errors:";
/usr/local/cpanel/3rdparty/perl/514/bin/perl <(curl -s --insecure https://raw.github.com/cPanelTechs/TechScripts/master/chkservd_errors.pl) 1 | tail -15
echo "Current time: "; date


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
cd /var/cpanel/updatelogs/; for i in $(\ls -rt | \tail -3); do egrep -i "Illegal instruction|Undefined subroutine|Error downloading" $i; done
#egrep -i "Illegal instruction|Undefined subroutine" /usr/local/cpanel/logs/easy/apache/*
cd /usr/local/cpanel/logs/easy/apache; for i in $(\ls -rt | \tail -5); do \egrep -i "Illegal instruction|Undefined subroutine" $i; done
badrepo=$(egrep "alt\.ru|ksplice-up" /etc/yum.repos.d/*);
echo -e $red$badrepo$clroff;

backup_log_dir='/usr/local/cpanel/logs/cpbackup';
if [ -d "$backup_log_dir" ]; then
 cd $backup_log_dir;
 # This can't go in hardware b/c it's only for cP servers
 #backup_interrupted=$(\ls -lrt|\tail -1|awk '{print $9}' | xargs -0 -I file echo file | tail -3;)
 backup_interrupted=$(\ls -lrt|\tail -1|awk '{print $9}' | xargs \grep EOF | \tail -3;)
 checkfor "$backup_interrupted" "Backup errors that could be a HD issue (full/bad):"
 cd ~;
 else
  echo -e $red"No backup log dir"$clroff;
  echo "Are account backups on? (#1 legacy, #2 current config:)";
  grep BACKUPACCTS /etc/cpbackup.conf /var/cpanel/backups/config;
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

# FB 63311
num_exclude_lines=$(grep -i exclude /etc/yum.conf|egrep -vi "#.*exclude" | wc -l)
if [ "$num_exclude_lines" -gt 1 ];
 then echo -e $red"There should only be 1 exclude line in /etc/yum.conf, but there's "$num_exclude_lines". (FB 63311)"$clroff;
fi

postfx_error=$(lsof -i :25 | awk '/localhost:smtp/ {print $2}')
if [ "$postfix_error" ]; then echo -e $red$postfix_error"\n\n see tristan email, FB 63493"$clroff; fi

fb63493=$(ps aux | grep -i postfi[x])
if [ "$fb63493" ];
 then echo -e "Postfix processes are running:\n"$fb63493"\nSee FB 63493\n"
fi

fb64265=$(\ls /root/perl5 2>/dev/null)
checkfor "$fb64265" "See FB 64265:"

# prompt to clean up any test email account on this server
tracks=$(\ls /root/cptestm/.login* 2>/dev/null)
if [ -e /root/cptestm/ ] && [ ! -e "$tracks" ]; then
#    old_test_email=$(grep cptestm /home/*/etc/*/passwd)
#    checkfor "$old_test_email" "Cruft test email account:"
#    echo "Found cruft test email account. Probably removed it on this date." > /root/cptestm/.login.log.$(date +%Y%m%d%H%M%S)
    touch /root/cptestm/.login.log.$(date +%Y%m%d%H%M%S)
    echo -e $red"Possibly a cruft test email account:"$clroff"\n grep cptestm /home/*/etc/*/passwd"
fi

#ac3524=$(fgrep -r open_tty /usr/local/apache/)
#checkfor "$ac3524" "see ac3524:"

