#!/bin/bash
# Original cpmig written by Phil Stark
# Original precpmig written by Marco Ferrufino
#
# https://github.com/philstark/cPMigration/
#
VERSION="0.0.1"
scripthome="/root/.precpmig"
# 
#############################################


#############################################
### functions
#############################################

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
	echo '-s <hostname or ip>, sourceserver'
	echo
	echo 'optional:'
	echo '-a <username or domain>, specify single account'
	echo '-l <filename>,  Read accounts from list'
	echo '-p sourceport'
	echo '-k keep archives on both servers'
    echo '-D use DEVEL scripts on remote setup (3rdparty)'
    echo '-S skip remote setup'
    echo '-e pr[e]-cpmig. Copy files for [e]valuation only. no migration is performed'
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

setup_remote(){
    control_panel=`$ssh root@$sourceserver "if [ -e /usr/local/psa/version	 ];then echo plesk; elif [ -e /usr/local/cpanel/cpanel ];then echo cpanel; elif [ -e /usr/bin/getapplversion ];then echo ensim; elif [ -e /usr/local/directadmin/directadmin ];then echo da; else echo unknown;fi;exit"` >> $logfile 2>&1
    if [[ $precpmig = "1" ]]; then
	    if [[ $control_panel = "cpanel" ]]; then
			echo "Source is cPanel"
			echo "The Source server is cPanel"  &> >(tee --append $logfile)
			   $ssh root@$sourceserver "
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
			dir_of_choice=/root
			if [ ! -d "$dir_of_choice" ]; then mkdir -p $dir_of_choice; fi
			new_dir=$dir_of_choice/cptemp_migration_$(date +%Y%m%d%H%M); mkdir $new_dir; cd $new_dir
			lwp-request http://cptechs.info/cpeval2 | perl > ./source.eval.out
			grep "^d:" source.eval.out | sed 's/^d:/s:/' > ./eval.in
			cat /var/cpanel/cpanel.config | sort | awk NF > ./source.cpanel.config
			for i in /etc/my.cnf /usr/local/lib/php.ini /var/cpanel/easy/apache/profile/_main.yaml /etc/exim.conf; do cp -pv $i ./; done
			tar -czvf /root/tomove.tar.gz $new_dir" >> $logfile 2>&1
	    else
	        echo "The Source server is not cPanel"  &> >(tee --append $logfile)
	        echo "Setting up scripts, Updating user domains" &> >(tee --append $logfile)
	        $ssh root@$sourceserver "
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
			/scripts/updateuserdomains-universal;" >> $logfile 2>&1
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
    criticals="`echo \"$logcheck\" | egrep "putsomethinghere"`"
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

while getopts ":s:p:a:l:kDhS" opt; do
	case $opt in
        s) sourceserver="$OPTARG";;
        p) sourceport="$OPTARG";;
        a) singlemode="1"; targetaccount="$OPTARG";;
        l) listmode="1"; listfile="$OPTARG";;
        k) keeparchives=1;;
        D) develmode="1";;
        S) skipremotesetup="1";;
        e) precpmig="1";;
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

after_action_report
