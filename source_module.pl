#!/usr/bin/perl
use strict;
use warnings;

my $filename = $ARGV[0];
my $function_name = $ARGV[1];
my @modules;

open(FH, $filename) or die "Can't open $filename";
while(<FH>) {
    if($_ =~ m/(use|require|include) ((\w*::)*\w+)/) {
    if ($2 =~ /(strict|warn)/) { next; }
    my $base = get_basedir();
        push @modules, "$base/$2.pm";
    }   
}
my @module_locations = map { s/::/\//g; $_; } @modules;
#print "@module_locations\n";
#print "$_\n" for @module_locations;

#print "\n(debug) Done with collection\n\n";

foreach (@module_locations) {
    my @found;
#print "(debug) outside GFH, argv[1] is: $ARGV[1]\n";
#print "(debug) dol_ is $_\n";
    chomp(my $mod_full_path = $_) ;
#print "(debug) mod_full_path is $mod_full_path\n";
    open(GFH, $mod_full_path) or die "Can't open $_";
    while(<GFH>) {
#print "(debug) inside GFH, argv[1] is: $ARGV[1]\n";
        if($_ =~ m/sub $ARGV[1]/) {
            push @found, $_; 
            print "$mod_full_path\n";
            print "@found\n";
        }   
    }   
    close(GFH);
}

sub get_basedir {
    my @bases = ("/usr/local/cpanel", "/opt/testsuite/lib");
    my @ret;
    foreach (@bases) {
        if (-d $_) { push @ret, $_ };
    }
    return "@ret";
}
