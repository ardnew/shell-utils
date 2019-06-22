#!/bin/bash

_PREFIX_BUP="  (BACKUP ) "
_PREFIX_INS="  (INSTALL) "

user=${USER}
overwrite=
while getopts "h?frou:" opt
do
  case "${opt}" in
    h|\?)
      cat <<USAGE
usage:

  $0 [-h?] [-ofr] [-u USER]

description:

  install and configure bash environment with default files

options:

  -h|-?          : display this helpful message
  -o|-f|-r       : overwrite existing files, do not create backup
  -u USER        : install files for user USER (requires sudo)

notes:

  by default, [-u USER] not specified, files are installed for the current user. 

  if the files already exist in the target user's directory, a backup is made of
  the existing file with a current date/time stamp appended. use one of the
  force flags [-ofr] to replace/overwrite without creating a backup.

USAGE
      exit -1
      ;;
    o|f|r)
      overwrite=1
      ;;
    u)
      user=${OPTARG}
      ;;
  esac
done
shift $( expr ${OPTIND} - 1 )

if [[ ${#@} -gt 0 ]]
then
  echo "WARNING: ignoring unrecognized argument(s): $@"
fi

use_sudo=
[[ "${user}" = "${USER}" ]] || use_sudo=1

. "$( dirname "${0}" )/bash_functions"

if ! silent id "${user}"
then
  echo "ERROR: no such user: ${user}"
  exit 1
fi

src_path=$( dirname "$( abspath "${0}" )" )
dst_path=$( eval echo "~${user}" )

echo "installing for user: ${user}"

files=( bash_profile bashrc bash_aliases bash_functions bash_colors hushlogin bash_logout vimrc screenrc gdbinit gdbinit_golang jlinkrc )

for curr in ${files[@]}
do
  src_file="${src_path}/${curr}"
  dst_file="${dst_path}/.${curr}"

  if [[ -f "${src_file}" ]]
  then
    echo "installing ${curr}"
    if [[ -f "${dst_file}" ]] && [[ -z ${overwrite} ]]
    then
      echo "${_PREFIX_BUP}${dst_file} -> $( stamp "${dst_file}" )"
    fi
    echo "${_PREFIX_INS}${src_file} -> ${dst_file}"
    cp "${src_file}" "${dst_file}"
  fi
done

