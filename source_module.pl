#!/usr/bin/perl
use strict;
use warnings;

my $filename = $ARGV[0];
my $function_name = $ARGV[1];
my @file_modules;

open(my $fh, '<', $filename) or die "Can't open $filename";
while(<$fh>) {
    if($_ =~ m/^(use|require|include) ((\w*::)*\w+)/) {
        my $mod_with_colons = $2; 
        next if ($mod_with_colons =~ /(strict|warn|POSIX)/);
        my $base = get_basedir();
        ( my $mod_with_slashes = $mod_with_colons ) =~ s/::/\//g ;
        if ( ! -f "$base/$mod_with_slashes.pm" ) { 
            print "$mod_with_colons not found: $base/$mod_with_slashes.pm\n";
            next;
        }   
        my $full_path = "$base/$mod_with_slashes.pm";
        push @file_modules, $full_path;
    }   
}

my @modules;
if ( !@file_modules ) { 
    print "Nothing found in the file provided, now searching \@INC...\n";
    @modules = @INC; 
}
else {
    @modules = @file_modules;
}

if ( !@modules ) { 
    print "Nothing found anywhere :(\n";
}

foreach (@modules) {
    my @found;
    my $mod_full_path = $_ ;
    open(my $mod_fh, '<', $mod_full_path) or die "Can't open $_";
    while(<$mod_fh>) {
        if($_ =~ m/sub $function_name/) {
            push @found, $_; 
            print "\nFound:\nvim $mod_full_path\n";
            print "@found\n";
        }   
    }   
    close($mod_fh);
}

sub get_basedir {
    my @bases = ("/usr/local/cpanel", "/opt/testsuite/lib");
    my @ret;
    foreach (@bases) {
        if (-d $_) { push @ret, $_ };
    }   
    my $last = pop(@ret);
    return $last;
}
