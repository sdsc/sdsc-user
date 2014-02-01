#!/usr/bin/perl
use strict;
use warnings;

# Author:   Robert Sinkovits (SDSC)
# Date:     8/29/13
# Modified: 1/27/14
# Synopsis: proj_details.pl lists project usage by user
# Usage:    proj_details.pl projid

# Host extracted from hostname command. Assumes that node names start
# with "[gordon|gcn|trestles]-"

my $host = `hostname`;
chomp($host);
$host =~ s/-.*//;
my ($base, $system);

if($host =~ /gordon/ || $host =~ /gcn/) {
    $base = "/home/servers/gordon";
    $system = "sdsc_gordon";
}

if($host =~ /trestles/) {
    $base = "/home/servers/trestles";
    $system = "sdsc_trestles";
}

my $acl = "${base}/ACL/new_dump_acls.pl.out";

open(FP, $acl)
    or die "Cannot open file $acl\n";

unless($#ARGV >= 0) {
    print("Error: Missing project ID\n");
    print("Usage: proj_details.pl projid\n\n");
    exit(1);
}

my $projid = $ARGV[0];
$projid =~ tr/[A-Z]/[a-z]/;
unless ($projid =~ /^[a-z]{3}[0-9]{3}$/) {
    print("Error: Project ID $projid of wrong form\n");
    print("Should be 3 letters followed by 3 digits\n\n");
    exit(1);
}


my $print_header = 1;

while(<FP>) {
    if(/^#/) {
	next; # Skip over commented lines
    }

    if(/$projid/) {
	my ($allow, $idstr, $alloc, $used, undef, $lastweek, $userpct, 
	    $canspend, $userused, $exp) = split;
	my($sys, $user, undef, undef) = split(/:/, $idstr);

	unless($sys eq $system) {
	    next;
	}
	
	if($print_header) {
	    print("\nProject $projid on $system\n");
	    print("Total allocation  $alloc\n");
	    print("Total spent       $used\n");
	    print("Expiration        $exp\n\n");
	    print("   userid        spent     can spend          real name        \n");
	    print("------------   ---------   ---------  -------------------------\n");
	    $print_header = 0; # Unset flag so that header info not printed again
	}
	    
	$userused =~ s/UU=//;
	$canspend =~ s/US=//;

	my $etcpasswd = `grep $user /etc/passwd`;
	my (undef, undef, undef, undef, $real, undef) = 
	    split(/:/, $etcpasswd);
        if (defined $real) {
	    $real =~ s/,.*//;
	} else {
	    $real = "<unknown>";
	}

	printf("%12s %10s   %10s  %s\n", $user, $userused, $canspend, $real);
    }

}

if($print_header) {
    print("\nProject $projid not found on $system\n");
}

print("\n");
