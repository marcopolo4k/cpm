#!/usr/bin/perl
use strict;
use warnings;
use IO::Tee;

system ( 'git fetch wombats' );

my %target_vms = (
    #'10.5.23.19' => '11.48.1.3/Cent5.11i686',
    '10.6.4.242' => '11.49.9999.66/Cent6.6x86_64',
    '10.6.5.52' => '11.49.9999.57/Cent6.6i686',
    '10.6.5.23' => '11.49.9999.66/Cent7.0x86_64',
);

my @lines = split /MW/, `cat ~/t1`;

my @matched_line;
my $jira_num;
my $test_name = "before set";
my $branch_name;
my $logfile;
my $br_cmt_msg; # branch's commit message mentioning the jira number

for (@lines) {
        if($_ =~ m/(\d{3}).+?([^ ]+\.t[est]{0,3})/s) {
        $jira_num = $1;
        $test_name = $2;

        if ( $test_name !~ /test$/ ) {
            print "(debug) test_name no test: $2\n";
            $test_name = $test_name . "est";
        };
        print "(debug) jira_num: $jira_num\n";
        print "(debug) test_name: $test_name\n";

        my $logfile = "/root/auto_run_logs/MW-$jira_num.log";
        $branch_name = `git branch -r | grep MW-$jira_num | head -1`;
        print "(debug) branch_name: $branch_name\n";
        system ("git checkout $branch_name 2>&1 | tee -a $logfile");
        print "\n";
        my $br_cmt_msg = `git log | grep MW-$jira_num`;
        if ( $br_cmt_msg ) {
            print "Change found, running...\n";
            runit($logfile, $br_cmt_msg);
        } else {
            system ("git checkout wombats_11.50 2>&1 | tee -a $logfile");
            system ("git pull 2>&1 | tee -a $logfile");
            $br_cmt_msg = `git log | grep MW-$jira_num`;
            if ( $br_cmt_msg ) {
                print "Change not found in it's own branch, so switched to wombats_11.50 and running now...\n";
                runit($logfile, $br_cmt_msg);
            } else {
                print "\nI didn't find the MW-$jira_num change in any branch, so nothing run.\n";
            };
        };
    };
};

sub runit {
    my ($logfile, $br_cmt_msg) = @_;
    my $count = 1;
    for my $vmip (sort keys %target_vms) {
        my $tee = new IO::Tee(\*STDOUT, new IO::File(">>$logfile"));
        select $tee;
        if ($count == 1) {print "\n\n ****************** \n"};
        print "\nThis branch's commit message(s) worth mentioning:\n$br_cmt_msg";
        print " ------------------ \n Running $test_name for $jira_num on $vmip/$target_vms{$vmip}:\n\n";
        system ("git log /usr/local/cpanel/t/qa/$test_name 2>&1 | grep MW-$jira_num 2>&1 | tee -a $logfile") == 0 or next;
        system (qq{script -afc "/usr/local/cpanel/build-tools/cpprove -v -h $vmip -s 10.5.2.118 /usr/local/cpanel/t/qa/$test_name" $logfile}) == 0 or next;
        select STDOUT;
        sleep 1;
        ++$count;
    };
};
