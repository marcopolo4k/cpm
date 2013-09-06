#!/usr/bin/perl
use strict;
my $debug=1;

# Open log file
open my $file, '/var/log/chkservd.log' or die "couldn't open file $!";


# For loop reads the file
my $lastdate="";
foreach my $line (readline $file) {

    # Set the date
    $lastdate = $1 if $line =~ /(\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2} [+-][0-9]{4}\]).*/ ;
    #if ( $debug == 1 ){ print $lastdate; }

    # These are usually trash lines
    if ($line !~ /Restarting|nable|\*\*|imeout|ailure|terrupt|100%|9[89]%|second/ && $line =~ /:\-\]/){
            print $lastdate, " ....\n";
        }
    # Main search
    if ($line =~ /Restarting|nable|\*\*|imeout|ailure|terrupt|100%|9[89]%|second/){
        my @array_fields = split /(\.){2,}/,$line;
        if (scalar(@array_fields) > 1){
            #if ( $debug == 1 ){ print scalar(@array_fields),"\n"; }
            foreach (@array_fields) {
                if (/:\-\]/) {
                    print $lastdate, " ", $_, "\n";
                }
            } 
        } else { 
                print $lastdate, " ", $line;
            }
        #if ( $debug == 1 ){ print "\nFOR LOOP DONE\n"; }
    }
}

close $file;
