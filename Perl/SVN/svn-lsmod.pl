#!/usr/bin/env perl
#
# $HeadURL$
# $Revision$
# $Author$
# $Date$
#
# DESC: lists the names of all files in an SVN working copy that have changed since
#       a specified revision. uses HEAD revision if unspecified
#
# AUTH: Andrew Shultzabarger
# DATE: Feb 2014
#

use strict;
use warnings;


die <<USAGE

  lists the names of all files in an SVN working copy that have changed since a
  specified revision

  USAGE

    $0 [wc-path [origin-rev]]

  PARAMETERS

    wc-path        (OPTIONAL) path to working copy. Uses current directory if
                   unspecified

    origin-rev     (OPTIONAL) numeric revision identifier for origin revision.
                   Uses HEAD revision if unspecified

  HISTORY

    - 4 Dec 2014: initial revision

USAGE
  if scalar @ARGV > 0 and $ARGV[0] =~ /-?-h(elp)?/;


my $path = $ARGV[0] || ".";
my $orev = $ARGV[1] || "HEAD";

die "error: not a directory: $path$/" unless -d $path;

open my $fh, "svn stat \"$path\" -quv |" or die "error: open: $!$/";

my @mod = ();

while (<$fh>)
{
  chomp;

  if (/^([MPS ]+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(.+)$/)
  {
    my ($mod, $rev, $cur, $usr, $nam) =
       (  $1,   $2,   $3,   $4,   $5);

    ($mod, $rev, $cur, $usr, $nam) =
      map { s/^\s+//; s/\s+$//; $_ }
        ($mod, $rev, $cur, $usr, $nam);

    next unless
      $nam !~ /^.?.$/;

    next unless
      length($mod) > 0 or $orev ne "HEAD" and $cur > $orev;


    my %f = ();
    $f{mod} = "$mod";
    $f{rev} = "$rev";
    $f{cur} = "$cur";
    $f{usr} = "$usr";
    $f{nam} = "$nam";
    push @mod, \%f;
  }
}

foreach (sort { $$a{cur} cmp $$b{cur} } @mod)
{
  print "($$_{cur}) $$_{nam}$/";
}

close $fh;
