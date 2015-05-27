#!/usr/local/cpanel/3rdparty/perl/514/bin/perl
use strict;
use warnings;

# my @list1 = `cat ~/t1`;
# my @list2 = `cat ~/t2`;
my $in1 = $ARGV[0];
my @list1 = `cat $in1`;

my $in2 = $ARGV[1];
my @list2 = `cat $in2`;

my @list1_pruned; # array of strings
for (@list1) {
    chomp(my $l1 = lc($_));
    # $l1 =~ s/=.*//;
    # $l1 =~ s/max//;
    # $l1 =~ s/^_//g;
    push(@list1_pruned, $l1);
}

my @list2_pruned; # array of strings
for (@list2) {
    chomp(my $l2 = lc($_));
    # $l2 =~ s/domain(s)*//;
    push(@list2_pruned, $l2);
}

# establish first group to compare 2nd against
my %first = map { $_ => 1 } @list1_pruned;

# # In Common
# print "\nItems in both $in2 and $in1:\n";
# my @incommon = grep {match_line($_)} @list2_pruned;
# print " $_\n" for @incommon;

# Differences
print "\n\nItems in $in2, missing from $in1:\n";
my @missing = grep {!match_line($_)} @list2_pruned;
print " $_\n" for @missing;

print "\n";

sub match_line {
    my ($line) = @_;
    my @words = split(/ /, $line);
    return grep { $first{$_} } @words;
}
