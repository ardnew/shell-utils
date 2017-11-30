#!/usr/bin/env perl
#
# $HeadURL$
# $Revision$
# $Author$
# $Date$
#
# Accepts a fully-qualified SVN URL and fetches all revisions stored on the server
#
# author : Andrew Shultzabarger
# date   : 30 January 2014
#

use strict;
use warnings;

use List::Util qw| max |;
use File::Path;
use File::Spec;
use POSIX;

my $svnbin = `which svn`; chomp $svnbin;
die sprintf "cannot locate or execute svn$/"
  unless -f $svnbin && -x $svnbin;

die sprintf <<USAGE

  export every revision of an svn repository

  WARNING: this can be enormous!

  usage:

    $0 <svn-url>

USAGE
  unless @ARGV > 0;

my %cmd =
(
  svnlog => sub { sprintf '%s log %s', $svnbin, shift },
  svnget => sub { sprintf '%s export -r %s --force %s "%s"', $svnbin, @_ },
);

open my $fh, &{$cmd{svnlog}}($ARGV[0]) . '|';
my @rev = grep { /\d/ } map { chomp, s/^r(\d+) .+/$1/ and $_ } <$fh>;
close $fh;

exit unless @rev > 0;

my $revdir = POSIX::strftime("SVN %m-%d-%Y %H:%M:%S", localtime);
my $rwidth = int(log(max @rev) / log(10) + 1);

foreach (@rev)
{
  print "Fetching revision $_... ";
  my $rp = File::Spec->catdir($revdir, sprintf('r%0*d', $rwidth, $_));
  mkpath($rp);
  $_ = &{$cmd{svnget}}($_, $ARGV[0], $rp); `$_`;
  print "done.$/";
}

