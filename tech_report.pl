#!/usr/local/cpanel/3rdparty/perl/514/bin/perl
#
# How to use this script:
#
# perl <(curl -s --insecure https://raw.github.com/cPMarco/cpm/master/tech_report.pl) ANALYST_NAME YEAR
#
# Run this from the directory the year folders are in.  Expecting:
# ./2014/Tickets/ANALYST_NAME/ANY_FILE_NAME
#

use strict;
# use warnings;

my $tech = shift or die "Please enter an analyst name.\n";
#my $main_dir = '/Users/marco/Dropbox/MacDocs/Git/cpm/';
chomp(my $main_dir = `pwd`);

my $input_year = shift;
my $year = get_year();
my $tech_dir = "$main_dir/$year/Tickets/$tech" ;
chomp(my $count = `ls $tech_dir | wc -l`);

print_output();

sub get_year {
    my $l_year = $input_year;
    if ($l_year !~ /\d{4}/){
        chomp($l_year = `date +%Y`);
    }
    return $l_year;
}

sub print_output {
    print "$tech\t$count\t($year)\n";
}
