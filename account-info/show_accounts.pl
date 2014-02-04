#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Env qw(USER);

# Modified by Robert Sinkovits 2/4/13
# (1) Single script can be used on Trestles and Gordon
# (2) Reports on ineligible users in tspent AND amied states

my $DEBUG = 0;  # 0 is off, 1 is on

# Host extracted from hostname command. Assumes that node names start
# with "[gordon|gcn|trestles]-"

my $host = `hostname`;
chomp($host);
$host =~ s/-.*//;
my $base;
my $SYSTEM;

if($host =~ /gordon/ || $host =~ /gcn/) {
    $base = "/home/servers/gordon";
    $SYSTEM = "sdsc_gordon";
    use lib "/home/servers/gordon/lib";
}

if($host =~ /trestles/) {
    $base = "/home/servers/trestles";
    use lib "/home/servers/trestles/lib";
    $SYSTEM = "sdsc_trestles";
}

use Accounting qw{read_accounts_file account_is_valid dumpHash};

# Shows all the project-accounts and their balances for a given user.
# Default is the current Unix user.  Data is extracted from the ACL
# file and used to create a jobscript file that will be accepted by
# the PBS job filter.
#
# Usage: ./show_accounts.pl 
#    OR: ./show_accounts.pl << name of user >>
#
# $Id: show_accounts.pl,v 1.4 2013/03/27 23:26:34 lcarson Exp $

my $usage = "usage: $0 name_of_user [OPTION]...

    name_of_user: user (if none given default to the current user)

    OPTIONS (not mandatory)
    -help:   display this message\n";

my $argc = $#ARGV + 1;
dprint ("argc is $argc");
dprint ("raw parameters: @ARGV\n");

my %options;

GetOptions("help" => \$options{help});

die "$usage" if ( $options{help} );

my $user        = $ARGV[0] || $USER;
my $found       = 0;    

# All users in the allow, tspent, uspent, inact, and amied states 
my ($allow, $tspent, $uspent, $inact, $amied) = read_accounts_file($base.'/ACL/new_dump_acls.pl.out');

# Multi-dimensional hash containing used and credit totals for all users in given state 
my ($balances) = get_balances($base.'/ACL/new_dump_acls.pl.out');

dprint ("$0:    SYSTEM is $SYSTEM      username is $user");

printf "%-12s %-12s %-8s %-12s %-8s\n",  "ID name", "project", "used", "available", "used_by_proj";
printf "------------------------------------------------------------\n";

# Look for users in the tspent (totally spent) or amied state who are ineligible to submit.
for ( keys %$tspent, keys %$amied )  {
    if ( $_ =~ m/^$SYSTEM:$user:/ ) {       # Look for this user on a specific platform
	$found     = 1;
	my $record = $_;
	
	my ( $system, $user, $account, $cpu ) = split /:/, $record;
	
	while ( my ( $key, $value ) = each (%$balances) ) {
	    if ( $key eq $record ) {
		printf "%-12s %-12s %-8d %-12d %-8d (ineligible)\n",  $user, $account, $value->{'used'}, $value->{'credit'}, $value->{'proj'}; }
	}
    }
}

# Users in the allow or eligible to submit state.  This is the default mode.
for ( keys %$allow ) {
    if ( $_ =~ m/^$SYSTEM:$user:/ ) {       # Look for this user on a specific platform
	$found     = 1;
	my $record = $_;
	
	my ( $system, $user, $account, $cpu ) = split /:/, $record;
	
	while ( my ( $key, $value ) = each (%$balances) ) {
	    if ( $key eq $record ) {
		printf "%-12s %-12s %-8d %-12d %-8d\n",  $user, $account, $value->{'used'}, $value->{'credit'}, $value->{'proj'}; }
	}
  }
}

if ( not $found )  {
  # Nothing found.
  print ("\nNo accounts found for user $user on platform $SYSTEM.\n\n");
}
else  { 
  if ( $options{tspent} )  {
    # Found something, if looking for tspent accounts say so.
    print ("\nUser $user has exhausted their allocation(s) on these account(s) on platform $SYSTEM and cannot submit.\n\n");
  }
  else  {
    # Found some eligible to submit accounts.
    print ("\nTo charge your job to one of these projects replace  << project >>\n");
    print ("with one from the list and put this PBS directive in your job script:\n");
    print ("#PBS -A << project >>\n\n");
  }
}

exit 0;

#
# Return balance info for all users in the 'allow' state.
#
# IN: the ACL file
#
# OUT: hash of hashes containing, in service units,
#   1.) user's usage   (amount spent)
#   2.) user's credit  (available to spend)
#
sub get_balances {
  my $ACLfile = shift || '';
  my %balances       = ();

  open( FP, "<$ACLfile" )
    or die "read_accounts_file: Cannot read account validation data file '$ACLfile'\n";

  while (<FP>) {
    chomp;

    next if m|^#|;          # Comments
    next if m|^$|;          # Blanks
    last if m|^__END__$|;   # Marks end of ACLs (optional, used for debugging purposes)

    # Sample record:
    # allow   sdsc_dash:lcarson:sds122:sddash             105995   0       # LWC=0       UP=100  US=105995   UU=0
    my ( $data, $comments )    = split /# /, $_;                        # Split on the hash
    my ( $LWC, $UP, $US, $UU ) = split /\s+/, $comments;                # Now split on whitespace everything right of the hash
    my ( $type, $acl, $alloc, $proj_used, $extra ) = split /\s+/, $data;    # Same for everything left of the hash

    # Key is the quartet and the values are hashes containing the used and credit available balances.
    if ( $type eq 'allow' or $type eq 'tspent' or $type eq 'amied') {
      $UU =~ s/UU=//;
      $US =~ s/US=//; 
      $balances{$acl}{used}     = $UU;
      $balances{$acl}{credit}   = $US;
      $balances{$acl}{proj}     = $proj_used;
    }
  }

# dumpHash('balances',    \%balances);  print "\n";    # This will dump the entire (large) hash
  close(FP);
  return \%balances;
}

sub dprint   { print STDERR join( '', "DEBUG: ", @_, "\n" ) if ($DEBUG); }

