#!/usr/bin/perl
use strict;
use warnings;

my $filename = $ARGV[0];
my $function_name = $ARGV[1];
my $specific_env = $ARGV[2] // 'or_else_its_empty';
my $print_pms_not_subs = $ARGV[3] // 'or_else_its_empty';
my @modules;
my %found;

open(my $fh, '<', $filename) or die "Can't open $filename";

# Populate modules:
while(<$fh>) {
    # TODO: this will eliminate "use Good::Module # here's a comment with the word use"
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

# Checking...
# Input File
if (!keys %found) {
    print "trying file...\n";
    @modules = ($filename);
    populate_found();
    print "Oh, it's in the same file you input:\n" if keys %found;
}

# Specific environment: Test Suite
if (!keys %found && $specific_env eq "ts") {
    print "trying teststuite locations...\n";
    @modules = grep_thru("/opt/testsuite/lib");
    populate_found();
}

# Specific environment: cPanel
# wow, this takes forever.  can't use it in this form
if (!keys %found && $specific_env eq "cp") {
    print "trying cpanel locations...\n";
    @modules = grep_thru("/usr/local/cpanel");
    populate_found();
}

print_results();

# @INC (defintely has to be in here, but it'll take 6 sec currently)
print "trying \@INC...\n";
@modules = @INC;
foreach my $blah (@modules) {
    if ( -d $blah ) { 
        my @l2a = get_more($blah);
        push (@modules, @l2a);
    }
}
populate_found();
print_results();

#TODO
#if (!keys %found) {
#    print "\nNothing found :(\n\n";
#}

sub get_basedir {
    my @bases = ("/usr/local/cpanel", "/opt/testsuite/lib");
    my @ret;
    foreach (@bases) {
        if (-d $_) { push @ret, $_ };
    }
    my $last = pop(@ret);
    return $last;
}

# really a wrapper for the next sub
sub populate_found {
    foreach (@modules) {
        my $one_module = $_ ; 
        if ($one_module =~ / /) {
            $one_module = quotemeta($one_module);
        }
        if (-f $one_module) {
            populate_found_with_a_file($one_module);
        }   
        elsif (-d $one_module) {
            my @files = glob "$_/*.pm";
            foreach my $file (@files) {
                populate_found_with_a_file($file);
            }   
        }   
    }   
}

sub populate_found_with_a_file {
            my $mod_full_path = shift;
            # most important debug statement:
            #print "(debug) mod_full_path is $mod_full_path\n";
            open(my $mod_fh, '<', $mod_full_path) or die "Can't open $mod_full_path";
            while (<$mod_fh>) {
                my $line = $_ ;
                if($line =~ m/sub $function_name/) {
                    my $line_num = $.;
                    my $unique_name = "line ".$line_num." of ".$mod_full_path;
                    $found{$unique_name} = $mod_full_path;
                }   
            }   
            close($mod_fh);
}

sub print_results {
    foreach ( keys %found ) { 
        my $sub_declaration = $_; 
        print "\nFound:\nvim $found{$sub_declaration}\n$sub_declaration\n";
    }
    print "\n";
    my $found = {};
}

# grep through the input directory, finding @modules to use in populate_found
sub grep_thru {
    my @dirs = @_ ;
    our @found_files = ();

    # this should go in a sub?
    foreach my $blah (@dirs) {
        if ( -d $blah ) { 
            my @l2a = get_more($blah);
            push (@dirs, @l2a);
        }
    }

    # Maybe this is inefficient, but this will return all files.
    # I could've only returned pm files, but maybe that would miss somthing.
    @found_files = @dirs;
    return @found_files;
}

sub get_more {
    my @files = <@_/*> ;
    return @files ;
}

