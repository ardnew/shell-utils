#!/bin/bash
#
# backs up the entire system, excluding various directories
# that are inappropriate to backup (e.g. proc-fs, dev tree,
# etc.), using rsync
#

include=/backup/include.files
exclude=/backup/exclude.files
lastbup=/backup/backup.log
lockbup=/backup/.backup.lock
rotates=/backup/rotate.sh

# comment out to actually perform backup
#rsyncdryrun=--dry-run

function readablesec
{
  if [[ $# -gt 0 ]]
  then
    seconds=$1
    if [[ $seconds -gt 86400 ]] # seconds in a day
    then
      printf "%d days " $(( seconds / 86400 ))
    fi
    date -d "1970-01-01 + $seconds seconds" "+%H hrs %M min %S sec"
  fi
}

function logline
{
  if [[ $# -gt 0 ]]
  then
    file=$1
    if [[ -f "${file}" ]]
    then
      echo "[backup]file=${file};md5="$( md5sum "${file}" | \grep -oP '^\S+' )";"
    fi
  fi
}

if [[ $# -ge 2 ]]
then

  # ---------------------------------------------------------------------------
  # verify arguments
  # ---------------------------------------------------------------------------

  source=$1
  target=$2

  if [[ -e "${lockbup}" ]]
  then
    currbup="$( cat ${lockbup} | tr -d '\n' )"
    echo "error: backup currently in progress: ${currbup}"
    exit 1
  fi

  if [[ ! -d "${source}" ]]
  then
    echo "error: invalid source directory: ${source}"
    exit 2
  fi

  if [[ ! -d "${target}" ]]
  then
    echo "error: invalid target directory: ${target}"
    exit 3
  fi

  # ---------------------------------------------------------------------------
  # configure filenames
  # ---------------------------------------------------------------------------

  realdate=$( date ) # use standard formatting with rotation script
  datetime=$( date "+%Y-%m-%d__%H-%M-%S" -d "${realdate}" )
  oskernel=$( printf "%s (%s)" \
              "$( lsb_release -d | \grep -oP '(?<=^Description:\t).+$' )" \
              "$( uname -r )" \
            | tr ' ' '_' )

  backupname="${oskernel}__${datetime}.tbz"
  targetname="${oskernel}"

  # ---------------------------------------------------------------------------
  # configure tool options
  # ---------------------------------------------------------------------------

  if [[ -z ${rsyncdryrun} ]]
  then
    rsyncprogress=--info=progress2
  else
    rsyncprogress=-v
  fi

  # ---------------------------------------------------------------------------
  # rotate the old backup files
  # ---------------------------------------------------------------------------

  rotatetime=$( date "+%s" )
  echo "===================================================================="
  echo " [+] rotating backup files ..."
  echo

  "${rotates}" "${target}" "${realdate}"

  rotateduration=$(( $( date "+%s" ) - ${rotatetime} ))
  echo
  echo " [+] done ($( readablesec ${rotateduration} ))"
  echo "===================================================================="
  echo

  # ---------------------------------------------------------------------------
  # perform the backup
  # ---------------------------------------------------------------------------

  backuppath="${target}/${backupname}"
  targetpath="${target}/${targetname}"

  # add a file indicating we are performing a backup
  echo "${backuppath}" > "${lockbup}"


  rsynctime=$( date "+%s" )
  echo "===================================================================="
  echo " [+] syncing filesystem with backup ..."
  echo

  # copy all files from root fs to the backup fs
  rsync ${rsyncdryrun} -axHAWXS \
      --numeric-ids \
      ${rsyncprogress} \
      --delete \
      --exclude-from="${exclude}" \
      --include-from="${include}" \
    "${source}/" \
    "${targetpath}"

  rsyncduration=$(( $( date "+%s" ) - ${rsynctime} ))
  echo
  echo " [+] done ($( readablesec ${rsyncduration} ))"
  echo "===================================================================="
  echo


  tarballtime=$( date "+%s" )
  echo "===================================================================="
  echo " [+] compressing backup filesystem ..."
  echo

  if [[ -z ${rsyncdryrun} ]]
  then
    # create a tarball using the SMP-aware bzip2 utility (to take advantage of
    # all 16 CPU cores we have) with highest+slowest compression ratio (-9)
    tar -c "${targetpath}" | pbzip2 -m2000 -p16 -9 -kcvz > "${backuppath}"
  fi

  tarballduration=$(( $( date "+%s" ) - ${tarballtime} ))
  echo
  echo " [+] done ($( readablesec ${tarballduration} ))"
  echo "===================================================================="
  echo

  if [[ -z ${rsyncdryrun} ]]
  then
    # log the backup
    logline "${backuppath}" >> "${lastbup}"
  fi

  # remove the backup lock file
  rm -f "${lockbup}"

  echo "===================================================================="
  echo " [+] backup completed in $( readablesec $(( ${rsyncduration} + ${tarballduration} )) )"
  echo " [+] current mirror:   ${targetpath}/"
  echo " [+] current snapshot: ${backuppath}"
  echo "===================================================================="


else

  cat <<USAGE
usage:
	bash $0 <source-dir> <target-dir>
USAGE
  exit 255

fi

