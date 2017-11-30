#!/usr/bin/env perl
#
# $HeadURL$
# $Revision$
# $Author$
# $Date$
#
# DESC: generates a recursive directory listing of all files in version control
#       for a given working copy. the listing generated is appropriate for use
#       in a VDD and/or SPS
#
# AUTH: Andrew Shultzabarger
# DATE: Feb 2014
#

use strict;
use warnings;

use Getopt::Std;
use File::Find;
use List::Util qw| max |;

# executable paths
my $svnversion = qw| svnversion |;


my $majorline = "=" x 80;
my $minorline = "-" x 80;

sub usage
{
  return <<"USAGE";

usage:

  perl "$0" [options] <path>

options:

  -f       : process regular files only (skip directories)
  -d       : group files by parent directory
  -c COLS  : output COLS files per line
  -s SEP   : separate columns with delimiter SEP (default: comma(,))
  -t TAG   : mark all directory entries with TAG
  -v       : verbose, more detailed output
  -h|-?    : display this help

USAGE
}

sub lastmod($)
{
  $_ = `$svnversion -c "$_[0]"`;
  s/^\s*//;
  s/\s*$//;

  return /:?(\d+)$/;
}

# ------------------------------------------------------------------------------
#  main line
# ------------------------------------------------------------------------------
my %opts = ();

getopts('fdc:s:t:vh?', \%opts);

print usage and exit if $opts{'h'} or $opts{'?'};

my $findpath = $ARGV[0] || ".";
my $findroot = Cwd::realpath($findpath);

$findpath =~ s/\/+$//;

my %versioned   = ();
my %dversioned  = ();
my @unversioned = ();
my $columns     = $opts{'c'} || 1;
my $separator   = $opts{'s'} || ',';

# prevent invalid column count
$columns = max($columns, 1);

if ($opts{'v'})
{
  print "$majorline$/";
  print "scanning: $findroot$/";
}

find(
  {
    wanted =>
      sub
      {
        return if $opts{'f'} and not -f;

        my $file = $_;
        my $idir = -d;
        my $drel = $File::Find::dir;
        my $path = File::Spec->catfile($File::Find::dir, $file);
        my $prel = $path;

        $drel =~ s/\/+$//g;
        $drel =~ s/^$findroot\/?//;
        $prel =~ s/^$findroot\/?//;

        $dversioned{$drel} = [] unless exists $dversioned{$drel};

        if (my ($last) = lastmod($path))
        {
          my $statref =
            {
                ent => $prel,
                fnm => $file,
                rev => $last,
                dir => $idir,
                tag => $idir ? $opts{'t'} : undef,
            };

          $versioned{$prel} = $statref;
          push @{$dversioned{$drel}}, $statref;
        }
        else
        {
          push @unversioned, $prel;
        }
      },
  },
  $findroot
);

if ($opts{'v'})
{
  print "$majorline$/";
  print "versioned files:$/";
  print "$minorline$/";
}

if ($opts{'d'})
{
  for my $dir (sort keys %dversioned)
  {
    next unless scalar @{$dversioned{$dir}} > 0;

    my $currpath = $dir ? File::Spec->catfile($findpath, $dir) : $findpath;
    $currpath =~ s/^\.\/(.+)$/$1/; # remove leading "./" if something follows it

    printf "%s:$/", $currpath;

    my $col = 0;

    for my $statref (@{$dversioned{$dir}})
    {
      my %stat = %{$statref};

      ++$col;

      if (defined $stat{'tag'})
      {
        printf "  %s [%s] (%s)", $stat{'fnm'}, $stat{'tag'}, $stat{'rev'};
      }
      else
      {
        printf "  %s (%s)", $stat{'fnm'}, $stat{'rev'};
      }

      print $separator;

      if ($col >= $columns)
      {
        print $/;
        $col = 0;
      }
    }

    print $/ unless 0 == $col;
  }
}
else
{
  my $col = 0;

  for my $ent (sort keys %versioned)
  {
    my %stat = %{$versioned{$ent}};

    ++$col;

    if (defined $stat{'tag'})
    {
      printf "  %s [%s] (%s)", $stat{'ent'}, $stat{'tag'}, $stat{'rev'};
    }
    else
    {
      printf "  %s (%s)", $stat{'ent'}, $stat{'rev'};
    }

    print $separator;

    if ($col >= $columns)
    {
      print $/;
      $col = 0;
    }
  }
}

if ($opts{'v'})
{
  print "$majorline$/";
  print "unversioned files:$/";
  print "$minorline$/";
  printf "  %s$/", $_ for @unversioned;
}
