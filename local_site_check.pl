#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

my $dom = "numdb2.test";
my $ip = "10.4.130.3";
#system ("curl -s numdb2.test --resolve '$dom:80:$ip'");

my $domain_list;
my %trueuserdata;

sub if_trueuserdomains {
    my $filename = "/etc/trueuserdomains";
    open my $fh,"<",$filename or die "Could not open file: $!";
    %trueuserdata=map{chomp;split ": "} <$fh>;

    for my $dom (keys %trueuserdata) {
        print "\n============ $dom ================\n";
        #print "$dom\n";
        system ("curl -s $dom --resolve '$dom:80:$ip'");
    }
    #return %trueuserdata;
};

if_trueuserdomains();
#print Dumper(\%trueuserdata);
