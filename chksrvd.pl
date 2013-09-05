#!/usr/bin/perl

#1.) open log file
open my $file, '/var/log/chkservd.log' or die "couldn't open file $!";


#2.) make a for loop that reads the file
my $lastdate="";
foreach my $line (readline $file) {

#3.) no longer plan to break file into hash of hashes called "service_status"

# Set the date
$lastdate = $1 if $line =~ /(\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2} [+-][0-9]{4}\]).*/ ;
#DEBUG
#print $lastdate ;

# getting the lines using the old regex
    if ($line !~ /Restarting|nable|\*\*|imeout|ailure|terrupt|100%|9[89]%|second/ && $line =~ /:\-\]/){
            print $lastdate, " ....\n";
        }
    if ($line =~ /Restarting|nable|\*\*|imeout|ailure|terrupt|100%|9[89]%|second/){
        @a1 = split /(\.){2,}/,$line;
        foreach (@a1) {
            if (/:\-\]/) {
                print $lastdate, " ", $_, "\n";
            }
        }
        #DEBUG print "\nFOR LOOP DONE\n";
    }
}

close $file;
