#!/usr/local/cpanel/3rdparty/perl/514/bin/perl
#
# How to use this script:
#
# perl <(curl -s --insecure https://raw.githubusercontent.com/cPMarco/cpm/master/tech_report.pl) ANALYST_NAME YEAR
#
# Run this from the directory the year folders are in.  Expecting:
# ./2014/Tickets/ANALYST_NAME/ANY_FILE_NAME
#

use strict;
# use warnings;

my $tech = shift or die "Please enter an analyst name.\n
Also, expecting this file structure:
./2014/Tickets/ANALYST_NAME/ANY_FILE_NAME\n";

# Get directory
chomp(my $main_dir = `pwd`);
# we can hard code this if needed, like:
#my $main_dir = '/Users/marco/Documents/TechRecords/';

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
