#!/usr/bin/env perl
#
# $HeadURL: http://rstok3-dev01.dev_okc.net/svn/APS_Team/trunk/Software/Perl/svn/svn-propset-keyword.pl $
# $Revision: 54 $
# $Author: shultzabarger $
# $Date: 2017-10-02 14:37:01 -0500 (Mon, 02 Oct 2017) $
#
# DESC: recursively scans a directory adding svn keyword properties to both the repo and the files
#       themselves using various configuration options. see the USAGE block below for details or run
#       this script with no arguments (or with the -h/--help argument)
#
# AUTH: Andrew Shultzabarger
# DATE: Feb 2014
#

use strict;
use warnings;

use Getopt::Long;
use File::Find;
use File::Spec;
use File::Basename;
use File::Copy;
use File::Temp qw| tempfile |;
use Fcntl;

my $FALSE = 0;
my $TRUE  = not $FALSE;

my $OPT_NOCOMMENT = "NONE";
my $OPT_AUTOCOMMENT = "[AUTO]";

my @extensionComment =
(
  [ qr/^ad[abs]$/                             , 'Ada',              q|--| ],
  [ qr/^([chm])(\g{-2}|(?<!m)(xx|pp|\+\+))?$/ , 'C/C++/Obj-C',      q|//| ],
  [ qr/^p([lm]|od|y[cdowz]?)|t|rb$/           , 'Perl/Python/Ruby', q|#|  ],
  [ qr/^sh$/                                  , 'sh/Bash/Zsh',      q|#|  ],
  [ qr/^(p(p|as)|dpr)$/                       , 'Pascal/Delphi',    q|//| ],
  [ qr/^vb[as]?$/                             , 'VBA/VBS',          q|'|  ],
  [ qr/^(java|cs)$/                           , 'Java/C#',          q|//| ],
  [ qr/^sql$/                                 , 'SQL',              q|--| ],
);

my $nullRedirect = $^O eq "MSWin32" ? "2>&1>NUL" : ">/dev/null 2>&1";

my $scriptName = fileparse($0);

# default keywords configuration. don't touch this, use the appropriate command
# line option instead.
my %keyword =
(
  HeadURL  => 1,
  Revision => 2,
  Author   => 3,
  Date     => 4,
  Id       => undef,
  Header   => undef,
);

# only read the first N lines to determine if a keyword block already exists in
# the file
my $keywordBlockSearchLines = 40;

my @searchRoot;       # file/dirs used to begin searching for files to propset

my $help;             # flag to display usage info
my $forcePerform;     # flag disabling all user confirmation
my $testPerform;      # flag enabling a test run over the file system
my $replaceKeywords;  # flag enabling replacement of keywords
my @keywordOrder;     # arguments added to --keyword option
my $includePath;      # argument added to --include option
my $excludePath;      # argument added to --exclude option
my @excludePaths;     # contents of file specified by --exclude argument option
my @filePattern;      # arguments added to --pattern option
my $commentPrefix;    # argument added to --comment option
my $verbosity;        # level of verbosity indicated with --verbose

my $filesModified;    # counter tracking number of files updated

sub usage
{
  return << "USAGE"

  \$ perl $scriptName <PATHS> [--keyword KEY1,KEY2,...] [--include INC] [--exclude EXC] [--pattern PAT1,PAT2,...] [--comment PREFIX|"$OPT_NOCOMMENT"] [--replace] [--force] [--test] [--verbose]

  Required arguments:

    PATHS          : space-delimited list of files and directories to begin
                     searching for files to modify with SVN keyword property.

  Optional arguments:

    --help,-h      : display this helpful usage information!

    --replace,-r   : replace the SVN keywords property if they are already set.
                     the default behavior is to ignore files that already have
                     SVN keywords property set.

    --force,-f     : force all operations to occur without prompting the user.
                     by default, the configuration is displayed to the user
                     before continuing, allowing them to not apply any unwanted
                     changes on the working copy. BE CAREFUL (or revert).

    --keyword,-k   : comma-delimited list of SVN-supported keywords to add to
                     each file. the order in which these keywords are provided
                     specifies the order in which they will appear in each file.
                     note that these keywords are case sensitive. the following
                     keywords are recognized (see SVN docs for details):

                       HeadURL
                       Revision
                       Author
                       Date
                       Id
                       Header

                     if this option is not provided, the following keywords are
                     used in order: HeadURL,Revision,Author,Date.

    --include,-i   : path to a file whose contents is a list of files to modify
                     with the SVN keyword property. one file/directory per line.

    --exclude,-x   : path to a file whose contents is a list of files to ignore
                     when setting the SVN keyword property. one file/directory
                     per line. these file paths have the highest precedence and
                     will override any files explicitly included.

    --pattern,-p   : comma-delimited list of file name patterns specifying what
                     files to include. file's found that do not match one
                     of these patterns will be ignored. patterns are perl-style
                     regular expressions (PCRE).

                     EXAMPLE: match all files with file name extension ".pas":

                       --pattern '\\.pas\$'

                         OR

                       -p '\\.pas\$'

                     EXAMPLE: match all C,C++,Obj-C source files:

                       --pattern '\\.(c(pp|\\+\\+|c)?|m)\$'

                         OR

                       -p '\\.c\$','\\.cpp\$','\\.c\\+\\+\$','\\.cc\$','\\.m\$'

                         OR

                       -p '\\.c\$' -p '\\.cpp\$' -p '\\.c\\+\\+\$' -p '\\.cc\$' -p '\\.m\$'

                     if this option is not provided, all files that are not
                     recognized as binary files according to perl's -B operator
                     will be modified (see: ``perldoc -f -B'' for specifics).

    --comment,-c   : string that represents start of a comment. each keyword
                     added to the file will have this prefix prepended.

                     if this option is not provided, an attempt is made to guess
                     the appropriate comment string by inspecting the file name
                     extension. the following table defines which comment string
                     (cmt) is used for the following known source files and the
                     regex pattern used to identify them:

                    +-----+-----------------+----------------------------------+
                    | cmt  language          pattern                           |
                    +-----+-----------------+----------------------------------+
                      --   Ada               ad[abs]
                      //   C,C++,Objective-C ([chm])(\\g{-2}|(?<!m)(xx|pp|\+\+))?
                      #    Perl,Python,Ruby  p([lm]|od|y[cdowz]?)|t|rb
                      #    Bash,sh,Zsh       sh
                      //   Pascal,Delphi     (p(p|as)|dpr)
                      '    VBA               vb[as]?
                      //   Java,C#           (java|cs)
                      --   SQL               sql

                     the pattern is anchored after the last period in the file
                     name all the way through to the end of the line, so these
                     extensions must match exactly. the pattern matching is not
                     case sensitive.

                     to disable auto-detecting the comment string and force the
                     keyword block be printed without any comments at all, use
                     the string "$OPT_NOCOMMENT" as comment (i.e. --comment "$OPT_NOCOMMENT").

    --test,-t      : without actually performing any updates, pretend to process
                     the current configuration. this is useful for ensuring
                     you've selected the correct files.

    --verbose,-v   : print more status information as this script operates.
                     repeated instances (e.g. "-vv") increases verbosity level.

USAGE
}

sub joinMultiArgs # combines multiple option invocations into single list
{
  return split /,/, join ",", @_;
}

sub uniq # removes duplicate elements from list, preserving order
{
  my %seen;
  return grep { not $seen{$_}++ } @_;
}

sub commentForFilename
{
  my ($filename) = @_;

  if ($filename =~ /^.*\.([^\/\.]+)$/i)
  {
    my $extension = $1;

    for my $c (@extensionComment)
    {
      return ($$c[1], $$c[2]) if $extension =~ $$c[0];
    }
  }

  return "";
}

sub keywordBlock
{
  my ($commentPrefix, @keywordOrder) = @_;

  # don't add a space in front unless a comment prefix was provided
  my $commentPrefixPadded = "$commentPrefix " if length $commentPrefix > 0;

  my $block = join $/, map { "$commentPrefixPadded\$$_\$" } @keywordOrder;

  # add a preceding and trailing comment line surrounding the block
  return "$commentPrefix$/$block$/$commentPrefix$/";
}

sub keywordBlockPattern
{
  my ($commentPrefix) = map { quotemeta } @_;

  return
    qr{
      (^\s*$commentPrefix\s*[\r\n]+)
      (^\s*$commentPrefix\s*\$(HeadURL|Revision|Author|Date|Id|Header)(:\s*[^\r\n]+)?\$\s*[\r\n]+){1,6}
      (^\s*$commentPrefix\s*[\r\n]+)
    }mxo;

  # intentionally leave off the end-of-line anchor at the very end of the
  # pattern so that we can slurp up all empty newlines and replace with a single
  # one separating this header block from the beginning of file contents
}

sub printConfig
{
  my ($searchRoot, $keywordOrder, $filePattern, $commentPrefix) = @_;

  my $searchRootDesc = join $/, map { "    \"$_\"" } @$searchRoot;
  my $filePatternDesc = join $/, map { "    \"$_\"" } @$filePattern;
  my $keywordBlockDesc = keywordBlock($commentPrefix, @$keywordOrder);

  print "$/PERFORMING UPDATES RECURSIVELY ON FILES/DIRECTORIES:$/$searchRootDesc$/";
  if (0 == @$filePattern)
  {
    print "$/ON ALL NON-BINARY FILES$/";
  }
  else
  {
    print "$/ON ONLY THE NON-BINARY FILES WHOSE NAME MATCHES ONE OF THE PATTERNS:$/$filePatternDesc$/";
  }
  print "$/BY INSERTING/REPLACING KEYWORD BLOCK WITH:$/$keywordBlockDesc$/";
}

sub resetFilePos # returns file cursor to beginning of file
{
  my ($fileHandle) = @_;

  #seek $fileHandle, 0, Fcntl::SEEK_SET;
  seek $fileHandle, 0, 0;
  $. = 0; # seek() will not reset the line counter! do it explicitly.
}

sub wantedFile
{
  my ($filePath, $filePattern, $replaceKeywords, $excludePaths) = @_;

  # ignore files specified in our --exclude file
  my $absPath = File::Spec->rel2abs($filePath);
  return $FALSE if scalar grep { $absPath =~ /$_/ } @$excludePaths;

  # do not perform any updates if the file is not under version control
  if (-f $filePath)
  {
    system sprintf 'svn info "%s" %s', $filePath, $nullRedirect;
    return $FALSE if $? != 0;

    # do not perform the keyword replacement if the file already has keywords
    # property set (and the user has not provided the --replace option)
    my $command = sprintf 'svn proplist "%s"', $filePath;
    open my $inHandle, "-|", $command or
      die "error: unable to read SVN properties of file: $filePath: $!$/";
    my $hasKeywordsProperty = grep { /^\s*svn:keywords\s*$/ } <$inHandle>;
    return $FALSE if $hasKeywordsProperty and not $replaceKeywords;
  }

  # we never want binary files
  return $FALSE if not -d $filePath and -B $filePath;

  # we always want directories; and we want all files if no patterns specified
  return $TRUE if -d $filePath or 0 == @$filePattern;

  # and finally return non-zero only if the name matches a given pattern
  my ($vol, $dir, $name) = File::Spec->splitpath($filePath);
  return scalar grep { $name =~ /$_/ } @filePattern;
}

sub processFile
{
  my
    (
      $filePath,
      $fileKind,
      $keywordBlock,
      $keywordBlockPattern,
      $keywordOrder,
      $testPerform
    ) = @_;

  print "    FILE ($fileKind [detected]): \"$filePath\": " if $verbosity > 0;

  if ($testPerform)
  {
    print $/ if $verbosity > 0;
    return;
  }

  open my $inHandle, "<", $filePath or
    die "error: unable to open file: $filePath: $!$/";

  my ($outHandle, $outFile) = tempfile();

  if (replaceKeywords(
        $inHandle, $keywordBlock, $keywordBlockPattern, $outHandle))
  {
    print "[REPLACED]$/" if $verbosity > 0;
  }
  else
  {
    insertKeywords($inHandle, $keywordBlock, $outHandle);
    print "[INSERTED]$/" if $verbosity > 0;
  }

  ++$filesModified;
  print "." if 0 == $verbosity;

  # preserve the original file's permissions after we move our temp output file
  # overwriting the original file
  my $perms = (stat $inHandle)[2] & 07777;
  chmod $perms | 0600, $outHandle;

  close $inHandle;
  close $outHandle;
  move($outFile, $filePath);

  my $command =
    sprintf 'svn propset svn:keywords "%s" "%s" %s',
      join(' ', @$keywordOrder),
      $filePath,
      $verbosity < 2 ? $nullRedirect : "";

  print "\t" if $verbosity > 1;
  system $command;
}

sub replaceKeywords
{
  my ($inHandle, $keywordBlock, $keywordBlockPattern, $outHandle) = @_;

  resetFilePos($inHandle);

  my $header = "";
  while (my $line = <$inHandle>)
  {
    last if $. > $keywordBlockSearchLines;
    $header .= $line;
  }

  my $result = $FALSE;
  if ($header =~ s/$keywordBlockPattern/$keywordBlock/)
  {
    resetFilePos($inHandle);
    resetFilePos($outHandle);

    print $outHandle $header;
    while (my $line = <$inHandle>)
    {
      next if $. <= $keywordBlockSearchLines;
      print $outHandle $line;
    }
    $result = $TRUE;
  }

  return $result;
}

sub insertKeywords
{
  my ($inHandle, $keywordBlock, $outHandle) = @_;

  resetFilePos($inHandle);
  resetFilePos($outHandle);

  print $outHandle $keywordBlock;
  while (my $line = <$inHandle>)
  {
    print $outHandle $line;
  }
}

die usage unless @ARGV > 0;

Getopt::Long::Configure("bundling");
GetOptions("help|h!"     => \$help,
           "force|f!"    => \$forcePerform,
           "replace|r!"  => \$replaceKeywords,
           "keyword|k=s" => \@keywordOrder,
           "include|i=s" => \$includePath,
           "exclude|x=s" => \$excludePath,
           "pattern|p=s" => \@filePattern,
           "comment|c=s" => \$commentPrefix,
           "test|t!"     => \$testPerform,
           "verbose|v+"  => \$verbosity);

die usage if $help;

@searchRoot         = uniq(@ARGV);
$replaceKeywords  ||= 0;
@keywordOrder       = uniq(joinMultiArgs(@keywordOrder));
@filePattern        = uniq(joinMultiArgs(@filePattern));
$includePath      ||= undef;
$excludePath      ||= undef;
@excludePaths       = ();
$commentPrefix    ||= $OPT_AUTOCOMMENT;
$testPerform      ||= 0;
$verbosity        ||= 0;
$filesModified      = 0;

if (defined $includePath)
{
  die "error: include file does not exist: $includePath$/"
    unless -f $includePath;

  open my $inHandle, "<", $includePath;
  push @searchRoot, map { s/^\s*//; s/\s*$//; $_ } <$inHandle>;
  close $inHandle;

  @searchRoot = uniq(@searchRoot);
}

if (defined $excludePath)
{
  die "error: exclude file does not exist: $excludePath$/"
    unless -f $excludePath;

  open my $inHandle, "<", $excludePath;
  push @excludePaths, map { s/^\s*//; s/\s*$//; $_ } <$inHandle>;
  close $inHandle;
}

my @invalidPath = grep { not -e $_ } @searchRoot;

die sprintf "error: no such files or directories: %s$/",
  join "", map { "$/  $_" } @invalidPath
    unless 0 == @invalidPath;

if (0 == @keywordOrder)
{
  @keywordOrder =
    sort { $keyword{$a} <=> $keyword{$b} }
      grep { defined $keyword{$_} } keys %keyword;
}

if (@_ = grep { not exists $keyword{$_} } @keywordOrder)
{
  my $unrecognized = join "", map { qq| "$_" | } @_;
  die "error: unrecognized keyword(s): $unrecognized$/";
}

printConfig(
    \@searchRoot,
    \@keywordOrder,
    \@filePattern,
    $OPT_NOCOMMENT eq $commentPrefix ? "" : $commentPrefix)
  if $verbosity > 0 or not $forcePerform;

if (not $forcePerform)
{
  print "$/CONTINUE? [y/N] ";
  my $response = <STDIN>; $response =~ s/^\s*//; $response =~ s/\s*$//;
  die "exiting!$/" unless $response =~ /^[Yy]/;
}

print $/ . "=" x 80 . $/.$/;

if (0 == $verbosity)
{
  print "Updating files ";
}

@searchRoot = map { Cwd::realpath($_) } @searchRoot;

for my $root (@searchRoot)
{
  if (-f $root)
  {
    my ($fileKind, $fileComment) = commentForFilename($root);

    my $selectedComment =
      $OPT_AUTOCOMMENT eq $commentPrefix
        ? $fileComment
        : $OPT_NOCOMMENT eq $commentPrefix
          ? ""
          : $commentPrefix;

    my $keywordBlock = keywordBlock($selectedComment, @keywordOrder);
    my $keywordBlockPattern = keywordBlockPattern($selectedComment);

    print "[$keywordBlock]$/";
    print "[$keywordBlockPattern]$/";

    processFile(
      $root,
      $fileKind,
      $keywordBlock,
      $keywordBlockPattern,
      \@keywordOrder,
      $testPerform)
        if wantedFile($root, \@filePattern, $replaceKeywords, \@excludePaths);
  }
  else
  {
    find(
      {
        preprocess => sub
        {
          return grep
            {
              wantedFile(
                File::Spec->catfile($File::Find::dir, $_),
                \@filePattern,
                $replaceKeywords,
                \@excludePaths)
            } @_;
        },
        wanted => sub
        {
          my $path = File::Spec->catfile($File::Find::dir, $_);
          if (-f $path)
          {
            my ($fileKind, $fileComment) = commentForFilename($_);

            my $selectedComment =
              $OPT_AUTOCOMMENT eq $commentPrefix
                ? $fileComment
                : $OPT_NOCOMMENT eq $commentPrefix
                  ? ""
                  : $commentPrefix;

            my $keywordBlock = keywordBlock($selectedComment, @keywordOrder);
            my $keywordBlockPattern = keywordBlockPattern($selectedComment);

            processFile(
              $path,
              $fileKind,
              $keywordBlock,
              $keywordBlockPattern,
              \@keywordOrder,
              $testPerform);
          }
        },
      },
      $root);
  }
}

print "$/$/Done. Files modified: $filesModified$/";
