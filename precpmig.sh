#!/bin/bash
# Original cpmig written by Phil Stark
# precpmig, by Marco Ferrufino is a proof of concept. It will eventually be converted into cpmig
#
VERSION="0.0.3"
scripthome="/root/.cppremig"
# 
#############################################


#############################################
### functions
#############################################

debug() {
 debug="on"
 if [ "$debug" = "on" ]; then
  echo -e $1
 fi
}

print_intro(){
    echo 'Pre-cPMigration'
    echo "version $VERSION"
    echo
}

print_help(){
	echo 'usage:'
	echo './cpmig -s <hostname or ip>'
	echo
	echo 'required:' 
    echo '-e pr[e]-cpmig. Copy files for [e]valuation only. no migration is performed'
	echo '-s <hostname or ip>, sourceserver'
	echo
	echo 'optional:'
	echo '-p sourceport'
	echo '-k keep archives on both servers'
    echo '-D use DEVEL scripts on remote setup (3rdparty)'
	echo '-i sk[I]p libkey check'
    echo '-h displays this dialogue'
    echo; echo; exit 1
}

install_sshpass(){
    echo 'Installing sshpass...'
	mkdir_ifneeded $scripthome/.sshpass
	cd $scripthome/.sshpass 
	wget -P $scripthome/.sshpass/ http://downloads.sourceforge.net/project/sshpass/sshpass/1.05/sshpass-1.05.tar.gz  
	tar -zxvf $scripthome/.sshpass/sshpass-1.05.tar.gz -C $scripthome/.sshpass/ 
	cd $scripthome/.sshpass/sshpass-1.05/
	./configure 
 	make 
    echo; echo
}

generate_accounts_list(){
    echo 'Generating accounts lists...'
    # grab source accounts list
    $scp root@$sourceserver:/etc/trueuserdomains $scripthome/.sourcetudomains >> $logfile 2>&1

    # sort source accounts list
    sort $scripthome/.sourcetudomains > $scripthome/.sourcedomains

    # grab and sort local (destination) accounts list
    sort /etc/trueuserdomains > $scripthome/.destdomains

    # diff out the two lists,  parse out usernames only and remove whitespace.  Output to copyaccountlist :)
    copyaccountlist="`diff -y $scripthome/.sourcedomains $scripthome/.destdomains | grep \< | awk -F':' '{ print $2 }' | sed -e 's/^[ \t]*//' | awk -F' ' '{ print $1 }' | grep -v \"cptkt\" `"
}

mkdir_ifneeded(){
    if [ ! -d $1 ]; then
        mkdir -p $1
    fi
}

set_logging_mode(){
    logfile="$scripthome/log/`date +%Y-%m-%y`-$epoch.log"
    case "$1" in
        verbose)
            logoutput="&> >(tee --append $logfile)"
            ;;
            *)
            logoutput=">> $logfile "
            ;;
    esac
}

# Libkey Check
lc_checkfor() {
	if [ "$1" ];
		then echo -e "$2\n$1\n$3" >> $logfile
		lc_num_fails=$((lc_num_fails+1))
		else echo "Passed." >> $logfile
        debug "inside positive checkfor num fails is $lc_num_fails"
	fi
    debug "inside checkfor num fails is $lc_num_fails"
}

lc_print_header() {
	echo -e "\nSearching for Libkey compromise. The '6 commands' are described here:\n
http://docs.cpanel.net/twiki/bin/view/AllDocumentation/CompSystem" >> $logfile
lc_num_fails=0
}

# Libkey Check: These general checks are not the 6 commands listed on the website
lc_general_checks() {
	echo -e "\nFirst general checks:"  >> $logfile
	libkey_ver_check=$(\ls -la $(ldd $(which sshd) |grep libkey | cut -d" " -f3))
	#length_check $libkey_ver_check
	libkey_check_results=$(echo $libkey_ver_check | egrep "1.9|1.3.2|1.3.0|1.2.so.2|1.2.so.0")
	lc_checkfor "$libkey_check_results" "libkey check failed due to version number: "

	libkey_dir=$(echo $libkey_ver_check | cut -d"/" -f2)
	libkey_ver=$(echo $libkey_ver_check |grep libkey | awk '{print $NF}')
	thelibkey=$(echo "/"$libkey_dir"/"$libkey_ver)
	assiciated_rpm=$(rpm -qf $thelibkey)

	assiciated_rpm_check=$(echo $assiciated_rpm | grep "is not owned by any package")
	if [ "$assiciated_rpm_check" ]; then
		echo -e "libkey check failed due to associated RPM:\n"$assiciated_rpm >> $logfile
		lc_num_fails=$((lc_num_fails+1))
	else
		echo -e "RPM associated with libkey file:\n"$assiciated_rpm >> $logfile
		echo "Passed." >> $logfile
	fi
}

# Libkey Check: Here the 6 commands listed on the website 
lc_command_1() {
	echo -e "\nCommand 1 Test:" >> $logfile
	keyu_pckg_chg_test=$(rpm -V keyutils-libs | egrep -v "\.[M\.]\.\.\.\.\.[T\.]\.")
	lc_checkfor "$keyu_pckg_chg_test" "keyutils-libs check failed. The rpm shows the following file changes: " "\n If the above changes are any of the 
 following, then maybe it's ok (probable false positive - you could ask the sysadmin what actions may have caused these):
 .M.....T
 However, if changes are any of the following, then it's definitely suspicious:
 S.5.L...
 see 'man rpm' and look for 'Each of the 8 characters'"
debug "after cmd 1, lc_num_fails is $lc_num_fails" >> $logfile
}

lc_command_2() {
	echo -e "\nCommand 2 Test:" >> $logfile
	cmd_2_chk=$(\ls -la $thelibkey | egrep "so.1.9|so.1.3.2|1.2.so.2");
	lc_checkfor "$cmd_2_chk" "Known bad package check failed. The following file is linked to libkeyutils.so.1: "
}

lc_command_3() {
	echo -e "\nCommand 3 Test:" >> $logfile
	cmd_3_chk=$(strings $thelibkey | egrep 'connect|socket|inet_ntoa|gethostbyname')
	lc_checkfor "$cmd_3_chk" "libkeyutils libraries contain networking tools: "
}

lc_command_4() {
	echo -e "\nCommand 4 Test:" >> $logfile
	check_ipcs_lk=$(for i in `ipcs -mp | grep -v cpid | awk {'print $3'} | uniq`; do ps aux | grep '\b'$i'\b' | grep -v grep;done | grep -i ssh)
	lc_checkfor "$check_ipcs_lk" "IPCS Check failed.  This is sometimes a false positive:"
}

lc_command_5() {
	echo -e "\nCommand 5 Test is not designed to run by this automated script" >> $logfile
}

lc_command_6() {
	echo -e "\nCommand 6 Test:" >> $logfile
	cmd6fail=0
	for i in $(ldd /usr/sbin/sshd | cut -d" " -f3); do
		sshd_library=$(rpm -qf $i);
		if [ ! "sshd_library" ]; then
			echo -e "\n"$i" has no associated library." >> $logfile;
            echo $sshd_library >> $logfile
			cmd6fail=$((cmd6fail+1))
		fi;
	done
	if [ "$cmd6fail" -gt 0 ]; then
		lc_num_fails=$((lc_num_fails+1))
	else echo "Passed." >> $logfile
	fi
    debug "after cmd 6, lc_num_fails is $lc_num_fails"
}


# Libkey Check: Print Summary and show the dates on the files
lc_summary() {
    debug "lc_num_fails is $lc_num_fails"
	if [ "$lc_num_fails" -gt 0 ]; then
		echo -e "\nPossible change times of the compromised files:" >> $logfile
		for i in $(\ls /lib*/libkeyutils*); do
			cmd_3_chk=$(strings $i | egrep 'connect|socket|inet_ntoa|gethostbyname');
			if [ "$cmd_3_chk" ]; then
				stat $i | grep -i change >> $logfile
			fi;
		done
		echo -e "\nTotal Number of checks failed: "$lc_num_fails" (out of 7 checks currently)\n\n
The following is a general guide to interpret results:
  1 check failed = possibly false positive. This is usually command 4 or 6
  2 checks failed = very likely real
  3+ checks failed = definitely real\n\n" >> $logfile

    echo -e "Destination server failed a critical error check.  See logs for more details:\n\n$logfile\n"  &> >(tee --append $logfile)
    exit 0
	fi
 
	echo >> $logfile
}

setup_remote(){
    control_panel=`$ssh root@$sourceserver "if [ -e /usr/local/psa/version	 ];then echo plesk; elif [ -e /usr/local/cpanel/cpanel ];then echo cpanel; elif [ -e /usr/bin/getapplversion ];then echo ensim; elif [ -e /usr/local/directadmin/directadmin ];then echo da; else echo unknown;fi;exit"` >> $logfile 2>&1
    debug "after assignment, control panel = $control_panel"  &> >(tee --append $logfile)
    eval_folder=evalfiles.$sourceserver
    debug "eval_folder is $eval_folder"

    if [[ $precpmig = "1" ]]; then
        echo -e "\n\nPre-cPMigration invoked.  This will not copy any accounts, just the evaluation files.\n\n" &> >(tee --append $logfile)

        cpeval_location=https://raw.github.com/cPanelSSP/cpeval2/master/cpeval2
        local_site_check_location=https://raw.github.com/cPMarco/cpm/master/local_site_check.sh
        the_date=$(date +%Y%m%d).$(date +%H).$(date +%M)
        eval_folder=evalfiles.$sourceserver
        debug "inside precpmig, eval_folder is $eval_folder"

        setup_scripts_plesk_cmds="
	        if [[ ! -d /scripts ]]; then
	            mkdir /scripts ;fi;
	        if [[ ! -f /scripts/pkgacct ]]; then
	            wget http://httpupdate.cpanel.net/cpanelsync/transfers_$pkgacctbranch/pkgacct/pkgacct-pXa -P /scripts;
	            mv /scripts/pkgacct-pXa /scripts/pkgacct;
	            chmod 755 /scripts/pkgacct
	        fi;
	        if [[ ! -f /scripts/updateuserdomains-universal ]]; then
	            wget http://httpupdate.cpanel.net/cpanelsync/transfers_$pkgacctbranch/pkgacct/updateuserdomains-universal -P /scripts;
	            chmod 755 /scripts/updateuserdomains-universal;
	        fi;
	        /scripts/updateuserdomains-universal;
        "

        setup_scripts_ensim_cmds="
            if [[ ! -d /scripts ]]; then 
                mkdir /scripts ;fi; 
	        if [[ ! -f /scripts/pkgacct ]]; then 
	            wget http://httpupdate.cpanel.net/cpanelsync/transfers_$pkgacctbranch/pkgacct/pkgacct-enXim -P /scripts;
	            mv /scripts/pkgacct-enXim /scripts/pkgacct;
	            chmod 755 /scripts/pkgacct
	        fi;
	        if [[ ! -f /scripts/updateuserdomains-universal ]]; then
	            wget http://httpupdate.cpanel.net/cpanelsync/transfers_$pkgacctbranch/pkgacct/updateuserdomains-universal -P /scripts;
	            chmod 755 /scripts/updateuserdomains-universal;
	        fi;
	        /scripts/updateuserdomains-universal;
        "

        setup_scripts_da_cmds="
	        if [[ ! -d /scripts ]]; then 
	            mkdir /scripts ;fi; 
	        if [[ ! -f /scripts/pkgacct ]]; then 
	        wget http://httpupdate.cpanel.net/cpanelsync/transfers_$pkgacctbranch/pkgacct/pkgacct-dXa -P /scripts;
	        mv /scripts/pkgacct-dXa /scripts/pkgacct;
	        chmod 755 /scripts/pkgacct
	            fi;
	            if [[ ! -f /scripts/updateuserdomains-universal ]]; then
	        wget http://httpupdate.cpanel.net/cpanelsync/transfers_$pkgacctbranch/pkgacct/updateuserdomains-universal -P /scripts;
	        chmod 755 /scripts/updateuserdomains-universal;
            fi;
            /scripts/updateuserdomains-universal;
        "

        createscripthome_cmds="
            # Pre-cPMigration Files
            mkdir -v $scripthome; mkdir -v $scripthome/$eval_folder;
        "

        cpanel_specific_cmds="
            cat /var/cpanel/cpanel.config | sort | awk NF > $scripthome/$eval_folder/source.cpanel.config
            cp -pv /etc/my.cnf $scripthome/$eval_folder/
            cp -pv /usr/local/lib/php.ini $scripthome/$eval_folder/
            cp -pv /var/cpanel/easy/apache/profile/_main.yaml $scripthome/$eval_folder/
            cp -pv /etc/exim.conf $scripthome/$eval_folder/
        "

        post_setup_cmds="
            # Grab some html from all websites, record for later comparison.  If this completes before cppremig is done, great.  If not
            # then no problem it can stay on the source server
            if [ ! -e $scripthome/$eval_folder/site_summary* ]; then
               curl -s --insecure $local_site_check_location | bash /dev/stdin '-o $scripthome/$eval_folder/' &
            fi

            curl -s --insecure $cpeval_location | perl > $scripthome/$eval_folder/source.eval.out
            grep '^d:' $scripthome/$eval_folder/source.eval.out | sed 's/^d:/s:Ensim:/' > $scripthome/$eval_folder/eval.in

            tar -czvf $scripthome/cPprefiles.$the_date.tar.gz $scripthome/$eval_folder/
        "
        
        dest_post_premigfilexfer_cmds() {
            debug "inside dest_post_premigfilexfer_cmds, eval_folder is $eval_folder"
            if [ -e $scripthome/cPprefiles.$the_date.tar.gz ]; then
                echo -e "\nFile transfer complete, now unpacking locally\n" &> >(tee --append $logfile)
            else echo -e "\nError with file transfer, see logs\n" &> >(tee --append $logfile)
            fi
            tar -C / -xzf $scripthome/cPprefiles.$the_date.tar.gz
            rm $scripthome/cPprefiles.$the_date.tar.gz
            mkdir -v $scripthome/$eval_folder 2>>$logfile
            curl -s --insecure $cpeval_location | perl > $scripthome/$eval_folder/destination.eval.out
            cat /var/cpanel/cpanel.config | sort | awk NF > $scripthome/$eval_folder/destination.cpanel.config
            grep ^d: $scripthome/$eval_folder/destination.eval.out >> $scripthome/$eval_folder/eval.in

            echo -e "Running cpeval on the input file: $scripthome/$eval_folder/eval.in\n\n" &> >(tee --append $logfile)
            curl -s --insecure $cpeval_location | perl /dev/stdin $scripthome/$eval_folder/eval.in &> >(tee --append $logfile)
            echo -e "\n\n" &> >(tee --append $logfile)
            echo -e "\nYou can also use:\ndiff --suppress-common-lines $scripthome/$eval_folder/source.eval.out $scripthome/$eval_folder/destination.eval.out | less\n\n" &> >(tee --append $logfile)
            echo -e "\n\nTransfer of pre-migration, evaluation files complete. See output in:\n$scripthome/$eval_folder\n\n" &> >(tee --append $logfile)
        }

        debug "before if, control panel = $control_panel"  &> >(tee --append $logfile)
	    if [[ $control_panel = "cpanel" ]]; then
           debug "after if, control panel = $control_panel"  &> >(tee --append $logfile)
           echo "Source is cPanel"
           echo "The Source server is cPanel"  &> >(tee --append $logfile)
           echo -e "\nCollecting files on source server (should take > 10s)\n" &> >(tee --append $logfile)

           $ssh root@$sourceserver "
           $setup_scripts_cmds
           $createscripthome_cmds
           $cpanel_specific_cmds
           $post_setup_cmds
           " >> $logfile 2>&1

           #Adding a log marker, copy the files over
           logcheck="$logcheck `echo \"Transferring pre-migration files\" &> >(tee --append $logfile)`"
           logcheck="$logcheck `$scp root@$sourceserver:$scripthome/cPprefiles.$the_date.tar.gz $scripthome/cPprefiles.$the_date.tar.gz &> >(tee --append $logfile)`"
           dest_post_premigfilexfer_cmds

	    elif [[ $control_panel = "plesk" ]]; then
	       echo "The Source server is Plesk"  &> >(tee --append $logfile)
	       echo "Setting up scripts, Updating user domains" &> >(tee --append $logfile)

	       $ssh root@$sourceserver "
           $setup_scripts_plesk_cmds
           $createscripthome_cmds
           $post_setup_cmds
           " >> $logfile 2>&1

           #Adding a log marker, copy the files over
           logcheck="$logcheck `echo \"Transferring pre-migration files\" &> >(tee --append $logfile)`"
           logcheck="$logcheck `$scp root@$sourceserver:$scripthome/cPprefiles.$the_date.tar.gz $scripthome/cPprefiles.$the_date.tar.gz &> >(tee --append $logfile)`"
           dest_post_premigfilexfer_cmds

	    elif [[ $control_panel = "ensim" ]]; then
	       echo "The Source server is Ensim"  &> >(tee --append $logfile)
	       echo "Setting up scripts, Updating user domains" &> >(tee --append $logfile)

	       $ssh root@$sourceserver "
           $setup_scripts_ensim_cmds
           $createscripthome_cmds
           $post_setup_cmds
           " >> $logfile 2>&1

           #Adding a log marker, copy the files over
           logcheck="$logcheck `echo \"Transferring pre-migration files\" &> >(tee --append $logfile)`"
           logcheck="$logcheck `$scp root@$sourceserver:$scripthome/cPprefiles.$the_date.tar.gz $scripthome/cPprefiles.$the_date.tar.gz &> >(tee --append $logfile)`"
           dest_post_premigfilexfer_cmds

	    elif [[ $control_panel = "da" ]]; then
	       echo "The Source server is DA"  &> >(tee --append $logfile)
	       echo "Setting up scripts, Updating user domains" &> >(tee --append $logfile)

	       $ssh root@$sourceserver "
           $setup_scripts_da_cmds
           $createscripthome_cmds
           $post_setup_cmds
           " >> $logfile 2>&1

           #Adding a log marker, copy the files over
           logcheck="$logcheck `echo \"Transferring pre-migration files\" &> >(tee --append $logfile)`"
           logcheck="$logcheck `$scp root@$sourceserver:$scripthome/cPprefiles.$the_date.tar.gz $scripthome/cPprefiles.$the_date.tar.gz &> >(tee --append $logfile)`"
           dest_post_premigfilexfer_cmds

		else echo -e "\nError in Panel Identification - None found\n" &> >(tee --append $logfile)
		fi
	fi
}




#############################################
### function error_check
#############################################
### This function checks the last segment of
### the logs for known errors.  It also looks
### for fail/bailout conditions
#############################################
error_check(){
    userid="`echo $logcheck | head -1 | awk {'print $2'}`"
    segment="`echo $logcheck | head -1 | awk {'print $1'}`"


    # GLOBAL CHECKS
    ###################
    #Critical checks
    ####################
    criticals="`echo \"$logcheck\" | egrep "check failed"`"
    if [[ ! $criticals == "" ]]; then
        echo -en "\E[30;41m Critical error(s) detected!\E[0m \n"
        echo "######!!!!! Critical error(s) detected! !!!!!#####" >> $logfile
        echo "$criticals" > >(tee --append $logfile)
        echo -en "\E[30;41m cP Migrations is bailing out \E[0m \n"
        exit
    fi
    ####################
    #Error checks
    ####################
    errors="`echo \"$logcheck\" | egrep \"putsomethinghere\"`"
    if [[ ! $errors == "" ]]; then
        echo -en "\E[40;31m Error(s) detected!\E[0m \n"
        echo "###### Error(s) detected! #####" >> $logfile
        echo "$errors" > >(tee --append $logfile)
        echo "cP Migrations is skipping further processing of $userid"
        stopcurrentuser="1"
        failedusers="$failedusers $userid"
    fi
    ####################
    #Warning checks
    ####################
    warnings=""
    warnings="$warnings `echo \"$logcheck\" | egrep \"/bin/gtar: Error\"`"
    if [[ ! $warnings == "" ]]; then
        #echo -en "\E[40;35m Warning(s) detected!\E[0m \n"
        echo "###### Warnings(s) detected! #####" >> $logfile
        echo "$warnings" >> $logfile
        warnusers="$warnusers $userid"
    fi

    #Phase Specific Checks
    #PHASE 1 - Packaging account
    #if [ $segment == '#@1#' ] ; then
    #echo > /dev/null
    #PHASE 2 - Transferring account
    #elif [ $segment = "#@2#" ] ; then
    #echo > /dev/null
    #PHASE 3 - Remove Package from source
    #elif [ $segment = "#@3#" ] ; then
    #echo > /dev/null
    #PHASE 4 - Rstoring account
    #elif [ $segment = "#@4#" ] ; then
    #echo > /dev/null
    #PHASE 5 - Remove package from destination
    #elif [ $segment = "#@6#" ] ; then
    #echo > /dev/null

    #fi
    echo "<plaintext> $logcheck </plaintext>" >> /var/cpanel/logs/copyacct_`echo $user`_`echo $sourceserver`_`echo $userepoch`_cPMigration
    logcheck=""
}
### END FUNCTION error_check

#############################################
### function after_action_report
#############################################
### This function prints and logs an after
### action report for the user at the end
### of the process.
#############################################
after_action_report(){
    logfile_afteraction="$scripthome/log/`date +%Y-%m-%y`-$epoch-after-action.txt"



    after_action_data="$after_action_data `echo \"cPMigration After-Action Report\" &> >(tee --append $logfile_afteraction)`"
    after_action_data="$after_action_data `echo \"  \" &> >(tee --append $logfile_afteraction)`"
    after_action_data="$after_action_data `echo \" Accounts that were migrated: \" &> >(tee --append $logfile_afteraction)`"
    after_action_data="$after_action_data `echo \"$verifiedusers\" &> >(tee --append $logfile_afteraction)`"
    after_action_data="$after_action_data `echo \"  \" &> >(tee --append $logfile_afteraction)`"
    after_action_data="$after_action_data `echo \" Accounts that were not migrated (see logs): \" &> >(tee --append $logfile_afteraction)`"
    after_action_data="$after_action_data `echo \"$missingusers\" &> >(tee --append $logfile_afteraction)`"

    cat $logfile_afteraction

}



#############################################
### get options
#############################################

while getopts ":s:p:a:l:kDhSei" opt; do
	case $opt in
        s) sourceserver="$OPTARG";;
        p) sourceport="$OPTARG";;
        a) singlemode="1"; targetaccount="$OPTARG";;
        l) listmode="1"; listfile="$OPTARG";;
        k) keeparchives=1;;
        D) develmode="1";;
        S) skipremotesetup="1";;
        e) precpmig="1";;
        i) skiplc="1";;
        h) print_help;;
        \?) echo "invalid option: -$OPTARG"; echo; print_help;;
        :) echo "option -$OPTARG requires an argument."; echo; print_help;;
    esac
done

if [[ $# -eq 0 || -z $sourceserver ]]; then print_help; fi  # check for existence of required var


#############################################
### initial checks
#############################################

# check for root
if [ $EUID -ne 0 ]; then
	echo 'cpmig must be run as root'
	echo; exit
fi

# check for resolving sourceserver
if [[ $sourceserver =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then :
elif [[ -z $(dig $sourceserver +short) ]]; then
    echo "$sourceserver does not appear to be resolving"
    echo; exit 1
fi


#############################################
### Pre-Processing
#############################################

# print into
print_intro


# install sshpass
if [ ! -f $scripthome/.sshpass/sshpass-1.05/sshpass ]; then
	install_sshpass
fi

# set SSH/SCP commands
read -s -p "Enter source ($sourceserver) root password: " SSHPASSWORD; echo
sshpass="$scripthome/.sshpass/sshpass-1.05/sshpass -p $SSHPASSWORD"
if [[ $sourceport != '' ]]; then  # [todo] check into more elegant solution
	ssh="$sshpass ssh -p $sourceport -o StrictHostKeyChecking=no"
	scp="$sshpass scp -P $sourceport"
else
	ssh="$sshpass ssh -o StrictHostKeyChecking=no"
	scp="$sshpass scp"
fi

# Make working directory
mkdir_ifneeded $scripthome/log

# Define epoch time
epoch=`date +%s`

# Set logging mode
set_logging_mode

# libkey check
if [[ $skiplc == "1" ]]; then
    echo "ONE SECURITY CHECK SKIPPED" &> >(tee --append $logfile)
else
    lc_print_header
    lc_general_checks
    lc_command_1
    lc_command_2
    lc_command_3
    lc_command_4
    lc_command_5
    lc_command_6
    lc_summary
    error_check
fi

# Setup Remote Server
if [[ $skipremotesetup == "1" ]]; then
    echo "REMOTE SETUP SKIPPED" &> >(tee --append $logfile)
else
    setup_remote
fi

# Generate accounts list
generate_accounts_list

# initiate variables
failedusers=""
warnusers=""

#############################################
### Process loop
#############################################

#after_action_report
