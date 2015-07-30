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
# ^ no, just use a bash_custom file

my $system = $ARGV[0];
my $user = $ARGV[1] // 'root';

my $help;

GetOptions ("system=s"   => \$system,
            "user=s"   => \$user,
            "help"   => \$help
)
or die("Error in command line arguments\n");

chomp(my @files = `cat system.plans/${user}\@$system`);

my $dir_for_files = 'provision_files';
make_tmp_dir();

my $sys_ip = '';
if ( $system =~ /\d/ ) {
    print "(debug) in ip section, system: [$system]\n"; 
    $sys_ip = $system;
    `echo "hostip=$sys_ip" >> $dir_for_files/.bash_profile`;
}

my $use_ssh_key = '';
foreach my $file (sort @files) {
    if ( $file =~ /\.ssh/ ) {
        if ( $file =~ /(.*)\.pub$/ ) {
            $file = $1;
        }
        $use_ssh_key = "-i $file";
    } elsif ( $file =~ /bash_profile/) {
        `echo '\n# $file' >> $dir_for_files/.bash_profile`;
        `cat files/$file >> $dir_for_files/.bash_profile`;
    } else {
        `cp files/$file $dir_for_files/`;
    }
}



`tar -cvf totransfer.tar $dir_for_files`;
`rm -rf $dir_for_files`;
`scp $use_ssh_key totransfer.tar ${user}\@$system:~/transferred_by_provision_script.tar`;



sub make_tmp_dir {
    if ( -d $dir_for_files ) {
        `mv $dir_for_files $dir_for_files.bak`;
    }
    `mkdir $dir_for_files`;
}

