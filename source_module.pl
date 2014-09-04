#!/usr/bin/perl
use strict;
use warnings;
use File::Find;

my $filename = $ARGV[0];
my $function_name = $ARGV[1];
my $specific_env = $ARGV[2];
my @modules;
my %found;

open(my $fh, '<', $filename) or die "Can't open $filename";

# Populate modules:
while(<$fh>) {
    # TODO: this will match "use Good::Module # here's a comment with the word use"
    if($_ =~ m/(\buse\b|\brequire\b|include\b)[ ]+((\w*::)*\w+)/ && $_ !~ m/#.*(\buse\b|\brequire\b|include\b)/) {
        my $mod_with_colons = $2; 
        next if ($mod_with_colons =~ /(strict|warn|POSIX)/);
        my $base = get_basedir();
        ( my $mod_with_slashes = $mod_with_colons ) =~ s/::/\//g ;
        if ( ! -f "$base/$mod_with_slashes.pm" ) { 
            print "$mod_with_colons not found: $base/$mod_with_slashes.pm\n";
            next;
        }   
        my $full_path = "$base/$mod_with_slashes.pm";
        push @modules, $full_path;
    }   
}

populate_found();
if (!keys %found) {
    print "trying file...\n";
    @modules = ($filename);
    populate_found();
    print "Oh, it's in the same file you input:\n" if keys %found;
}
if (!keys %found) {
    print "trying \@INC...\n";
    @modules = @INC;
    populate_found();
}
if (!keys %found && $specific_env eq "ts") {
    print "trying teststuite locations...\n";
    grep_thru("/opt/testsuite/lib");
}
if (!keys %found) {
    print "\nNothing found :(\n\n";
}

print_results();


sub get_basedir {
    my @bases = ("/usr/local/cpanel", "/opt/testsuite/lib");
    my @ret;
    foreach (@bases) {
        if (-d $_) { push @ret, $_ };
    }
    my $last = pop(@ret);
    return $last;
}

sub populate_found {
    foreach (@modules) {
        my $mod_full_path = $_ ;
        open(my $mod_fh, '<', $mod_full_path) or die "Can't open $_";
        while(<$mod_fh>) {
            if($_ =~ m/sub $function_name/) {
                $found{$_} = $mod_full_path; 
            }   
        }   
        close($mod_fh);
    }   
}

sub print_results {
    foreach ( keys %found ) { 
        my $sub_declaration = $_; 
        print "\nFound:\nvim $found{$sub_declaration}\n$sub_declaration\n";
    }
    print "\n";
}

sub grep_thru {
    my @dirs = @_ ;

    ## main processing done here
    my @found_files = ();
    #orig:
    #my $pattern = qr/$function_name/;

    find( \&wanted, @dirs );        ## fullpath name in $File::Find::name

    sub wanted
    {
        next if $File::Find::name eq '.' or $File::Find::name eq '..';    
        open my $file, '<', $File::Find::name or die "Error openning file: $!\n";
        while( defined(my $line = <$file>) )
        {        
            if($line =~ /sub $function_name/)
            {
                # TODO: this generates "not stay shared" error. I can get around it by making
                # the sub anonymous, but proly better to use return values
                push @found_files, $File::Find::name;    
                last;            
            }        
        }
        close ($file);    
    }

    foreach (@found_files) {
        $found{$_} = $_; 
    }
}
