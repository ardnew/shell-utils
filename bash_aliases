################################################################################
#
#  file: ${HOME}/.bash_aliases
#
#  date: 03/18/2013
#
#  auth: Andrew Shultzabarger
#
#  desc: various helper aliases
#
################################################################################

# ------------------------------------------------------------------------------
#  supportive environment variables
# ------------------------------------------------------------------------------

test ${HOST_IS_OSX}                                                            \
  && export LSOPT_DETAIL_DEF="lsh"                                             \
  || export LSOPT_DETAIL_DEF="lsh --group-directories-first"
export LSOPT_DETAIL_ALL="a$LSOPT_DETAIL_DEF"
export LSOPT_DETAIL_MOST="A$LSOPT_DETAIL_DEF" # same as -a but hides ".", ".."


# ------------------------------------------------------------------------------
#  bash built-ins and standard tools
# ------------------------------------------------------------------------------

alias      resource='. ${HOME}/.bash_profile ; echo ". ${HOME}/.bash_profile"'

test ${HOST_IS_OSX}                                                            \
  && alias       ls='ls -G'                                                    \
  || alias       ls='ls --color=auto'
alias             l='ls -CF'
alias            ll="l -$LSOPT_DETAIL_DEF"
alias            la="l -$LSOPT_DETAIL_MOST"
alias           lla="l -$LSOPT_DETAIL_ALL"
alias         bytes='xxd -c1'
alias          bits='xxd -c1 -b'
alias            df='df -h'
alias            du='du -h'
alias          time='command time' # use the system util, not the shell builtin
alias          sudo='sudo -E'
alias          less='less -r'
[[ $( grep --version 2>&1 | \grep -ci gnu ) -eq 0 ]]                           \
  && alias     grep='grep --color=always -E'                                   \
  || alias     grep='grep --color=always -P' # PCRE by default
alias         egrep='grep --color=always -E'
alias          cols='tput cols'

alias    asciitable='chars | head -n 38'
alias     charclass='chars | tail -n 45'

alias  perl-deparse='perl -MO=Deparse'

alias      cpstruct='rsync -avhu --progress -f"+ */" -f"- *"'
alias      syncdirs='rsync -avhu --progress'
alias       finddos="grep -IUlr $'\r'"

alias         bdiff='bcompare'
alias         sdiff='sdiff -w$(tput cols)'

alias     systemctl='systemctl --no-pager'
alias           sdc='systemctl'

alias           sci='svn commit'
alias           srm='svn rm'
alias           sup='svn update'

#
# Cygwin stuff
#
if test ${HOST_IS_CYGWIN}
then
  alias      runcmd='cmd /c'
  alias    unixpath='cygpath.exe --unix --absolute'
  alias     winpath='cygpath.exe --windows --absolute --long-name'
  alias     nixpath='unixpath'
  alias updatedbwin='updatedb --prunefs="smbfs SMBFS vfat VFAT fat32 FAT32 nfs NFS proc" --prunepaths="/tmp /var/tmp /usr/tmp /mnt /media /proc /cygdrive/e /cygdrive/f /cygdrive/t /cygdrive/v /cygdrive/w /cygdrive/x /cygdrive/y"'
fi

#
# OS X stuff
#
if test ${HOST_IS_OSX}
then
  alias   restart.dock='killall -KILL Dock'
  alias   restart.menu='killall -KILL SystemUIServer'
  alias restart.finder='killall -KILL Finder'
  alias         simctl='xcrun simctl'
fi

#
# and private stuff
#
alias   irssi.lt="ssh -tC lt 'screen -list && screen -Udr || screen -U irssi'"

