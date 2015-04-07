#!/usr/bin/perl
use strict;
use warnings;
use IO::Tee;

chdir ('/usr/local/cpanel/');

# TODO: git status --porcelain
system ( 'git fetch wombats' );

my %target_vms = (
    '10.6.18.25' => '11.48.3.0/Cent6.6x86_64',
    '10.6.5.52' => '11.49.9999.78/Cent6.6x86_64',
    '10.5.23.126' => '11.49.9999.64/Cent6.6x86_64',
    '10.6.18.23' => '11.49.9999.74/Cent7.0x86_64',
);
my $selenium_server = '10.6.17.25';

my @lines = split /MW/, `cat ~/t1`;

my @matched_line;
my $jira_num;
my @tests;
my $branch_name;
my $default_branch = "wombats_11.50";
my $logfile;
my $br_cmt_msg; # branch's commit message mentioning the jira number

for (@lines) {
    $_ =~ /(\d{3})/;
    $jira_num = $1;
    # if end up allowing manual branch names:
    #$branch_name = $_ =~ /^branch:\s*(\S+)/;
    @tests = ($_ =~ /(\S+\.t(?:est)?)/g);

    for (@tests) {
        my $test_name = $_;
        if ( $test_name !~ /test$/ ) {
            print "(debug) test_name no test: $2\n";
            $test_name = $test_name . "est";
        }
        print "(debug) jira_num: $jira_num\n";
        print "(debug) tests array:\n";
        print "(debug) $_\n" for @tests;

        my $logfile = "/root/auto_run_logs/MW-$jira_num.log";
        chomp($branch_name = `git branch -r | egrep MW.?$jira_num | head -1`);
        print "(debug) branch_name: [$branch_name]\n";
        if ($branch_name) {
            system ("git checkout $branch_name 2>&1 | tee -a $logfile");
            print "\n";
        }

        my $br_cmt_msg = `git log | egrep MW.?$jira_num`;
        if ( $br_cmt_msg ) {
            print "Change found, running...\n";
            runit($test_name, $logfile, $br_cmt_msg);
        } else {
            system ("git checkout $default_branch 2>&1 | tee -a $logfile");
            system ("git pull 2>&1 | tee -a $logfile");
            $br_cmt_msg = `git log | egrep MW.?$jira_num`;
            if ( $br_cmt_msg ) {
                print "Change not found in it's own branch, so switched to $default_branch and running now...\n";
                runit($test_name, $logfile, $br_cmt_msg);
            } else {
                print "\nI didn't find the MW-$jira_num change in any branch, so nothing run.\n";
            }
        }
    }
}

sub runit {
    my ($test_name, $logfile, $br_cmt_msg) = @_;
    my $count = 1;
    for my $vmip (sort keys %target_vms) {
        my $tee = new IO::Tee(\*STDOUT, new IO::File(">>$logfile"));
        select $tee;
        if ($count == 1) {print "\n\n ~~~~~~~~~~~~~~~~~~ \n"};
        print "\nThis branch's commit message(s) worth mentioning:\n$br_cmt_msg";
        print " ------------------ \n Running $test_name for $jira_num on $vmip/$target_vms{$vmip}:\n\n";

        # only 2 lines that need commenting for debug:
        system ("git log /usr/local/cpanel/t/qa/$test_name 2>&1 | grep MW-$jira_num 2>&1 | tee -a $logfile") == 0 or next;
        system (qq{script -afc "/usr/local/cpanel/build-tools/cpprove -v -h $vmip -s $selenium_server /usr/local/cpanel/t/qa/$test_name" $logfile}) == 0 or next;

        select STDOUT;
        sleep 1;
        ++$count;
    };
};
