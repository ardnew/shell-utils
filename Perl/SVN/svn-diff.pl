#!/usr/bin/env perl

# TODO:
#   1) specify single path with 2 revisions
#   2) auto select HEAD revision in certain cases
#   3) auto select WC in certain cases
#

use strict;
use warnings;

$| = 1; # autoflush

use constant
  {
    _TAB => ' ' x 4,
  };

use Getopt::Long qw| :config auto_abbrev bundling_override no_ignore_case |;

use ardnew::IO qw| :all |;
use ardnew::Lists qw| :all |;
use ardnew::Files qw| :all |;
use ardnew::Util qw| :all |;

my $VERBOSE = 0;

my $SELFPATH = abspath $0;
my $SELFNAME = basename $SELFPATH;

my @SVN_BIN = qw| svn |;
my @BC3_BIN = qw| bcomp |;

sub usage
{
  return <<USAGE
usage:

  $SELFNAME [-h]
  $SELFNAME [-v] -1 PATH\@REV -2 PATH\@REV

USAGE
}

sub shell_cmd
{
  # see the perldoc on 'system' for more info

  my ($cmd) = join " ", @_;
  my ($ret);
  my (@out);

  # each element of @_ may contain spaces (i.e. multiple terms)
  my ($program_name) = ($cmd =~ /\w+/g);

  if ($VERBOSE > 0)
  {
    my $subcmd = $cmd;
    # remove all outermost surrounding parentheses
    while ($subcmd =~ s/^\s*\(\s*(.*)\s*\)\s*$/$1/g) { ; }
    sinfo "forking child process:";
    sinfo _TAB . $subcmd;
  }

  open my $io, "-|", $cmd . " 2>&1"
    or ohno "could not execute '$program_name': $!";

  if ($VERBOSE > 1)
  {
    while (<$io>)
    {
      push @out, $_ if wantarray;
      chomp;
      sinfo _TAB x 2 . $_;
    }
  }
  close $io;

  my ($ret_wait) = ($ret = $?);

  if (-1 == $ret)
  {
    ohno "failed to fork or wait for child: $!";
  }
  elsif ($ret & 127)
  {
    ohnof 'child died with signal %d (%s coredump)',
      [ ($ret & 127), ($ret & 128) ? 'with' : 'without' ];
  }
  else
  {
    $ret >>= 8;

    if ($VERBOSE > 1)
    {
      sinfo "child terminated:";
      sinfo _TAB . "returned $ret ($ret_wait)";
    }
  }

  # scalar context just returns the exit value of the command; list context will
  # return (in order): the cmd exit value, the wait(2) syscall return value, and
  # a list containing each line output from the command (STDOUT -and- STDERR)
  return
    wantarray ? ($ret, $ret_wait, @out) : $ret;
}

sub subshell_cmd
{
  # same as sub shell_cmd{}, but encloses command in parens "(...)" so that you
  # can safely navigate the fs, prepare env, etc. without affecting the current
  # environment in which this script is executing. if you `cd` somewhere, the
  # subshell will exit when finished -- leaving PWD unchanged

  return 0 unless 0 < @_;

  my ($cmd) = do { local $" = q| |; "( @_ )" };
  my ($ret_s, @ret_l);

  sinfo "spawning subshell ...(" if $VERBOSE > 0;

  {
    if (wantarray) { @ret_l = shell_cmd $cmd }
              else { $ret_s = shell_cmd $cmd }
  }

  sinfo ")... returned from subshell" if $VERBOSE > 0;

  return
    wantarray ? @ret_l : $ret_s;
}

sub svn_export
{
  my ($bin, $path, $rev, $dir) = @_;

  my $exec_retcode =
    shell_cmd "'$bin' export ".
      "--force ". # tmpdir creates the dir, use --force to overwrite
      "--revision $rev ".
      "'$path' ".
      "'$dir' ".
      "";

  if (0 != $exec_retcode)
  {
    ohno "failed to export repo path, re-run with verbose>=2 (-vv) to view export log";
  }
}

my ($svn_bin) = grep { 0 == system 'type -t "'.$_.'" 2>&1 > /dev/null' } @SVN_BIN;
my ($bc3_bin) = grep { 0 == system 'type -t "'.$_.'" 2>&1 > /dev/null' } @BC3_BIN;

ohno 'required SVN utility not found: ' . join "|", @SVN_BIN
  unless defined $svn_bin;
ohno 'required Beyond Compare 3 utility not found: ' . join "|", @BC3_BIN
  unless defined $bc3_bin;

my %option = ();
GetOptions(\%option,
  'verbose|v+',
  'help|h!',
  'path1|1=s',
  'path2|2=s',
  );

$VERBOSE = $option{verbose} if exists $option{verbose};

final usage unless defined $option{path1} and defined $option{path2};

my ($path1, $rev1) = ($option{path1} =~ m|^(.+)[,@](\d+)$|);
my ($path2, $rev2) = ($option{path2} =~ m|^(.+)[,@](\d+)$|);

ohno 'invalid path: ' . $option{path1}
  unless defined $path1 and defined $rev1;
ohno 'invalid path: ' . $option{path2}
  unless defined $path2 and defined $rev2;

my $export_dir_path1 = tmpdir(sprintf("%s@%d", basename($path1), $rev1));
my $export_dir_path2 = tmpdir(sprintf("%s@%d", basename($path2), $rev2));

svn_export($svn_bin, $path1, $rev1, $export_dir_path1);
svn_export($svn_bin, $path2, $rev2, $export_dir_path2);

sinfo "comparing revisions:";
sinfo _TAB . "($rev1) $path1";
sinfo _TAB . "($rev2) $path2";

my $exec_retcode =
  shell_cmd "'$bc3_bin' /fileviewer='Folder Compare' '$export_dir_path1' '$export_dir_path2'";

if ($VERBOSE > 0)
{
  sinfo "cleaning up:";
  sinfo _TAB . "rm -rf '$export_dir_path1' '$export_dir_path2'";
}
rmr $export_dir_path1, $export_dir_path2;

if (0 != $exec_retcode)
{
  ohno "failed to open diff results, re-run with verbose>=2 (-vv) to view diff log";
}
