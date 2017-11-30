#!/bin/bash

################################################################################
#
#  file: ${HOME}/.bashrc
#
#  date: 03/18/2013
#
#  auth: Andrew Shultzabarger
# 
#  desc: initialization script for all bash shell sessions (both interactive
#        and non-interactive!)
#
################################################################################

# ------------------------------------------------------------------------------
#  session-wide variables
# ------------------------------------------------------------------------------

export PARENT_PROFILE="/etc/profile"
[[ -f "${PARENT_PROFILE}" ]] && . "${PARENT_PROFILE}" # first and foremost

export BASH_ALIASES="${HOME}/.bash_aliases"
export BASH_FUNCTIONS="${HOME}/.bash_functions"
export BASH_COLORS="${HOME}/.bash_colors"

export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups

# paths to prepend to $PATH in descending precedence
BIN_PATH=( "${HOME}/.bin" "${HOME}/bin" "/opt/local/bin" "/usr/local/bin" )

# paths to prepend to LD_LIBRARY_PATH in descending precedence
LIB_PATH=( "${HOME}/.lib" "${HOME}/lib" )

# ------------------------------------------------------------------------------
#  some other convenient constants
# ------------------------------------------------------------------------------

export FALSE=0
export TRUE=1 

export DATETIME_FORMAT_LONG="%Y-%h-%d %H:%M:%S"
export DATETIME_FORMAT="%Y-%m-%d__%H-%M-%S"
export TIMESTAMP_FORMAT="%s"

export  KB_BYTES=$(( 10 ** 3  ))
export KiB_BYTES=$((  2 ** 10 ))
export  MB_BYTES=$((  $KB_BYTES ** 2  ))
export MiB_BYTES=$(( $KiB_BYTES ** 2  ))
export  GB_BYTES=$((  $KB_BYTES ** 3  ))
export GiB_BYTES=$(( $KiB_BYTES ** 3  ))

# ------------------------------------------------------------------------------
#  configure executable and library paths
# ------------------------------------------------------------------------------

# we need this function -before- we actually source .bash_functions
function pathmunge
{
  ! echo "${1}" | \grep -Eq "(^|:)${2}($|:)" && echo "${2}:${1}" || echo "${1}"
}

for (( idx=${#BIN_PATH[@]}-1 ; idx>=0 ; --idx ))
do
  [[ -d "${BIN_PATH[idx]}" ]] \
    && PATH=$( pathmunge "${PATH}" "${BIN_PATH[idx]}" )
done

for (( idx=${#LIB_PATH[@]}-1 ; idx>=0 ; --idx ))
do
  [[ -d "${LIB_PATH[idx]}" ]] \
    && LD_LIBRARY_PATH=$( pathmunge "${LD_LIBRARY_PATH}" "${LIB_PATH[idx]}" )
done

export PERL5LIB=$( pathmunge "${PERL5LIB}" "${HOME}/.lib/perl" )

# ------------------------------------------------------------------------------
#  configure aliases and functions only after we've set $PATH and friends
# ------------------------------------------------------------------------------

[[ ${OSTYPE} = *darwin* ]] && export HOST_IS_OSX=1
[[ ${OSTYPE} = *cygwin* ]] && export HOST_IS_CYGWIN=1

[[ -f "${BASH_ALIASES}" ]] && . "${BASH_ALIASES}"
[[ -f "${BASH_FUNCTIONS}" ]] && . "${BASH_FUNCTIONS}"
[[ -f "${BASH_COLORS}" ]] && . "${BASH_COLORS}"

# create option flags to include all of my perl modules for the inline perl `pe` alias
pkgdir=ardnew
peflag=-le #default flags for ``pe'' alias
pnflag=-lne
ppflag=-lpe
allmod=

while read -re dir
do
  if [[ -d "${dir}/${pkgdir}" ]]
  then
    mod=("${dir}/${pkgdir}"/*.pm)
    mod=(${mod[@]##*/}) # remove everything before the filenames
    mod=(${mod[@]%.pm}) # remove the file extensions
    mod=(${mod[@]/%/=:all}) # add the ":all" export tag to each module
    allmod=("${mod[@]/#/-Mardnew::}")
    break
  fi
done < <(perl -e 'print join $/, @INC')

alias     pe="perl ${allmod[@]} ${peflag}"
alias     pn="perl ${allmod[@]} ${pnflag}"
alias     pp="perl ${allmod[@]} ${ppflag}"
alias   walk="pe 'my \$c = shift; walk sub { eval \$c; if(\$@){ print \$@; exit } }, @ARGV'"
alias   sift="pe 'sift shift, @ARGV'"
alias  sifti="pe 'sifti shift, @ARGV'"
alias   bury="pe 'bury shift, @ARGV'"
alias  buryi="pe 'buryi shift, @ARGV'"

# prompt design
ss="\[$BIBlack\]::\[$Color_Off\]"
DATETIME="\[$IWhite\]\D{%d-%b-%Y %H:%M:%S}\[$Color_Off\]"
HOSTNAME="\[$BICyan\]"'$(hostname)'"\[$Color_Off\]" # inefficient, but functional
CURRPATH="\[$ICyan\]\w\[$Color_Off\]"
EXITCODE="\[$BIBlack\]\$?\[$Color_Off\]"

if [[ -n ${SSH_CONNECTION} ]]
then
  CLIENTIP=( ${SSH_CONNECTION} )
  CONNSTAT="$IBlue${CLIENTIP[0]}$BIGreen@$Color_Off"
else
  CONNSTAT=
fi

if [[ -n ${ENV_PREFIX} ]] && [[ "${LYNXOS_PREFIX}" == "${ENV_PREFIX}" ]]
then
  PLATFORM="\[$IBlue\]LynxOS-178 CDK\[$Color_Off\]"
else
  test ${HOST_IS_OSX} \
    && PLATFORM="\[$Cyan\]$(uname -sm)\[$Color_Off\]" \
    || PLATFORM="\[$Cyan\]$(uname -om)\[$Color_Off\]"
fi

if [[ "$(whoami)" == "root" ]]
then
  PROMPT="\[$Red\]|\[$Color_Off\]"
else
  PROMPT="|"
fi

export PS1="\n${PROMPT} ${DATETIME} ${ss} ${PLATFORM} ${ss} ${CONNSTAT}${HOSTNAME} ${ss} ${CURRPATH} ${ss} ${EXITCODE}\n${PROMPT} "
export PROMPT_COMMAND='echo -ne ""'

                                                      [[ $- != *i* ]] && return
# ------------------------------------------------------------------------------
#  everything below this point will not be evaluated by non-interactive shells
# ------------------------------------------------------------------------------

