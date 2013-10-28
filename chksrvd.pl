#!/usr/bin/perl
use strict;
#use Time::Piece;
#use Time::Seconds;
#use Date::Calc;

#Todo:
# - better method of time math
# - allow for options (only last x lines, or y hours)

sub debug {
    my $debug_toggle = "no";
    if ($debug_toggle eq "yes") {
        print "(debug) @_\n";
    }
}

# Variables
my $line;
my $lastdate;
my @curdate;
my $lasthr;
my $lastmin;
my $line_has_date=0;
my $dhr;
my $dmin;
my $every_n_min;
chomp(my $every_n_sec=`grep chkservd_check_interval /var/cpanel/cpanel.config | cut -d= -f2`);

# Set search time for 'system too slow' check
# IDK why this didn't work:
#if ( !$every_n_sec =~ /\D/ ) \{
#if ( !looks_like_number $every_n_sec || $every_n_sec < 1 ) \{
if ( $every_n_sec < 1 ) {
    &debug("every_n_sec is not an acceptable digit, using default 10");
    $every_n_min=10;
} else { 
    &debug("every_n_sec is a digit, using it");
    $every_n_min = ( (300 + $every_n_sec) / 60 );
    &debug("every_n_min is: $every_n_min");
}

# Open log file
open my $file, '/var/log/chkservd.log' or die "couldn't open file $!";

# For loop reads the file
foreach $line (readline $file) {
    #&debug($line);
    # Set the date
    if ($line =~ /(\[\d{4}(-\d{2}){2} \d{2}(:\d{2}){2} [+-]\d{4}\]).*/) {
        $line_has_date = 1;

        ###########
        # Trying to use Time::Piece, didn't work
        #my $for_time_piece;
        #my $time;
        #if ($1=~/\[(.*) +/) {
        #    $for_time_piece = $1;
        #    $time = $for_time_piece;
        #}
        #my $time->datetime($1);
        #$t->datetime
        #&debug("from Time::Piece: $time");
        #$time += ONE_DAY;
        #&debug("from Time::Piece: $time");
        ###########

        $lastdate = $1;
        @curdate = split(/:/,$lastdate);
        if ($curdate[0] =~ / (\w+$)/) {
            $curdate[0] = $1; 
        }
        &debug("hr is $curdate[0], min is $curdate[1]\n");

        # Calculate time difference between this & last check, in minutes & hours
        # If this is the first time run, establish the starting values
        if ($lasthr == '' && $lastmin == '') {
            $lasthr = $curdate[0];
            $lastmin = $curdate[1];
        }
        else {
            $dhr = $curdate[0]-$lasthr;
            $dmin = $curdate[1]-$lastmin;
        }

    }

    # These are usually trash lines
    if ($line !~ /Restarting|nable|\*\*|imeout|ailure|terrupt|100%|9[89]%|second/ && $line =~ /:\-\]/){
        print $lastdate, " ....\n";
    }
    # Main search
    if ($line =~ /Restarting|nable|\*\*|imeout|ailure|terrupt|100%|9[89]%|second/){
        my @array_fields = split /(\.){2,}/,$line;
        if (scalar(@array_fields) > 1){
            #&debug(@array_fields);
            foreach (@array_fields) {
                if (/:\-\]/) {
                    print $lastdate, " ", $_, "\n";
                }
            } 
        } else { 
                print $lastdate, " ", $line;
            }
        #&debug("\nFOR LOOP DONE\n");
    }

    # If this line includes a date, either one is true:
    # difference in minutes > limit
    # difference in hours is == 1, AND check that difference in minutes is not too negative
    # difference in hours is > 1
    &debug("line_has_date is: $line_has_date\nlastmin is: $lastmin\nlasthr is: $lasthr\ndmin is: $dmin\nevery_n_min is: $every_n_min\ndhr is: $dhr\ndmin is: $dmin\nevery_n_min is: $every_n_min");
    if ($line_has_date && ($lastmin!=0 || $lasthr!=0) && ($dmin>$every_n_min || ($dhr==1 && ($dmin>(-1*(60-$every_n_min)))) || $dhr>1 )) {
        print "$lastdate Check took longer than $every_n_min minutes. (hr:min): $dhr:$dmin\n";
    }

    # Set last hr & min for next round
    if ($line_has_date) {
        $lastmin=@curdate[1]; 
        $lasthr=@curdate[0]
    }
}

close $file;
