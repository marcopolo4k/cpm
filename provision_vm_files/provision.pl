#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# goal: put files on a new vm
# problem: files might already exist. so currently im putting the existing file in a local folder??  bad solution.  i need to:
# 1. make a backup of the file
# 2. get the file in memory - a var
# 3. compare what I'm about to put with what's in the file.
# 4. overwrite(? i guess i have to) the common parts, leaving the original text in there.
# ^ no, just use a bash_auto file?

my $system = $ARGV[0];
my $user = $ARGV[1] // 'root';

if ( @ARGV < 1 or 2 < @ARGV or $ARGV[0] =~ /^-h$|^-help$|^--help$/ ) { 
    help();
    exit;
}

my $help;

GetOptions ("system=s"   => \$system,
            "user=s"   => \$user,
            "help"   => \$help
)
or die("Error in command line arguments\n");

chomp(my @files = `cat system.plans/${user}\@$system`);

my $dir_for_files = 'provision_files';
make_tmp_dir();

# TODO: use CPANEL by default if system is an IP address without a system file
my $sys_ip = '';
if ( $system =~ /(\d{1,3}\.){3}\d{1,3}/ ) {
    $sys_ip = $system;
    `echo "hostip=$sys_ip" >> $dir_for_files/.bash_custom`;
}

my $use_ssh_key = '';
my $use_port = '';
foreach my $file (sort @files) {
    if ( $file =~ /\.ssh/ ) {
        if ( $file =~ /(.*)\.pub$/ ) {
            $file = $1;
        }
        $use_ssh_key = "-i $file";
    } elsif ( $file =~ /port:(\d*)/) {
        $use_port = "-P $1";
    } elsif ( $file =~ /bash_profile/) {
        `echo '\n# $file' >> $dir_for_files/.bash_custom`;
        `cat files/$file >> $dir_for_files/.bash_custom`;
    } else {
        `cp files/$file $dir_for_files/`;
    }
}



`tar -cvf totransfer.tar $dir_for_files`;
`rm -rf $dir_for_files`;
`scp $use_ssh_key $use_port totransfer.tar ${user}\@$system:~/transferred_by_provision_script.tar`;
`scp $use_ssh_key $use_port expand.pl ${user}\@$system:~/provision_expand.pl`;



sub make_tmp_dir {
    if ( -d $dir_for_files ) {
        `mv $dir_for_files $dir_for_files.bak`;
    }
    `mkdir $dir_for_files`;
}

sub help {
    print "\nPlease enter one or two arguments:\n";
    print "provision.pl <system_name|ip_address> [username]\n\n";
    print "/system.plans - list of systems' plans\n";
    print "/files - list of files to include in those plans\n\n";
}
