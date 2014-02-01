#!/usr/bin/perl
use strict;
use warnings;

# Author:   Robert Sinkovits (SDSC)
# Date:     10/10/13
# Modified: 10/10/13
# Synopsis: ddp_summary.pl
# Usage:    ddp_summary.pl

# Host extracted from hostname command. Assumes that node names start
# with "[gordon|gcn|trestles]-"

my $host = `hostname`;
chomp($host);
$host =~ s/-.*//;
my $base;

if($host =~ /gordon/ || $host =~ /gcn/) {
    $base = "/home/servers/gordon";
}

if($host =~ /trestles/) {
    $base = "/home/servers/trestles";
}

my @systems = ("sdsc_gordon", "sdsc_trestles");

my $acl = "${base}/ACL/new_dump_acls.pl.out";


for my $system (@systems) {
    print "\nsystem: $system\n";
    print " proj       alloc        used     expires\n";
    print "------  ----------  ----------   ---------\n";
    open(FP, $acl) or die "Cannot open file $acl\n";

    my %alloc;
    my %used;
    my %exp;
    
    while(<FP>) {
	if(/^#/) {
	    next; # Skip over commented lines
	}
	
	my ($allow, $idstr, $alloc, $used, undef, $lastweek, $userpct, 
	    $canspend, $userused, $exp) = split;
	
	unless (defined $idstr) {
	    next;
	}
	
	my($sys, $user, $proj, undef) = split(/:/, $idstr);
	
	if ($sys eq $system && $proj =~ /ddp/) {
	    $alloc{$proj} = $alloc;
	    $used{$proj}  = $used;
	    $exp{$proj}   = $exp;
	}
    }

    
    for my $key (sort keys %alloc) {
	printf("%6s  %10s  %10s   %9s\n", $key, $alloc{$key}, $used{$key}, $exp{$key});
    }   

    close(FP);
}
