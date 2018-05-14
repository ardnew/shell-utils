#!/bin/bash
#
# removes obsolete backup tarballs from the backup drive to preserve space
#
# there are three schemes that can protect a backup file from being sacrificed:
#
#   1) the backup was created within the last 7 days (including today)
#   2) the backup was created on a sunday within the last 4 weeks (including this week)
#   3) the backup was created on the first of the month within the last 12 months (including this month)
#
# if a backup file does not fall into any one of these three categories, it will be deleted.
#

DEBUG=0

lastbup=/backup/backup.log
lockbup=/backup/.backup.lock

weekly_dow="Sunday"
weekly_kept=4
monthly_kept=12

function logline
{
  if [[ $# -gt 0 ]]
  then
    file=$1
    if [[ -f "${file}" ]]
    then
      echo "[rotate]file=${file};md5="$( md5sum "${file}" | \grep -oP '^\S+' )";"
    fi
  fi
}

if [[ $# -ge 2 ]]
then

  # ---------------------------------------------------------------------------
  # verify arguments
  # ---------------------------------------------------------------------------

  source=$1
  datetime=$2

  if [[ -e "${lockbup}" ]]
  then
    currbup="$( cat ${lockbup} | tr -d '\n' )"
    echo "error: backup currently in progress: ${currbup}"
    exit 1
  fi

  if [[ ! -d "${source}" ]]
  then
    echo "error: invalid backup directory: ${source}"
    exit 2
  fi

  # ---------------------------------------------------------------------------
  # configure filenames
  # ---------------------------------------------------------------------------

  oskernel=$( printf "%s (%s)" \
              "$( lsb_release -d | \grep -oP '(?<=^Description:\t).+$' )" \
              "$( uname -r )" \
            | tr ' ' '_' )

  # ---------------------------------------------------------------------------
  # build a list of filenames we should keep
  # ---------------------------------------------------------------------------

  keep=()
  daily=()
  weekly=()
  monthly=()

  recent_weekly=

  # keep all backups within the last 7 days (including today)
  for day in 0 1 2 3 4 5 6
  do

    _date=$( date -d "${datetime} -${day} days" )
    _day=$( date -d "${_date}" "+%A" )
    _name="${oskernel}__"$( date -d "${_date}" "+%Y-%m-%d__" )

    [[ "${weekly_dow}" == "${_day}" ]] && recent_weekly="${_date}"

    daily+=( "${_name}" )

  done

  # keep all weekly backups for the last N weeks (including this week)
  for week in $( seq 0 $(( weekly_kept - 1 )) )
  do

    _date=$( date -d "${recent_weekly} -${week} weeks" )
    _name="${oskernel}__"$( date -d "${_date}" "+%Y-%m-%d__" )

    weekly+=( "${_name}" )

  done

  day_of_month=$( date -d "${datetime}" "+%d" )
  first_of_month=$( date -d "${datetime} -$(( day_of_month - 1 )) days" )

  # keep all monthly backups for the last N months (including this month)
  for month in $( seq 0 $(( monthly_kept - 1 )) )
  do

    _date=$( date -d "${first_of_month} -${month} months" )
    _name="${oskernel}__"$( date -d "${_date}" "+%Y-%m-%d__" )

    monthly+=( "${_name}" )
    
  done

  keep=( "${daily[@]}" "${weekly[@]}" "${monthly[@]}" )

  keep_file()
  {
    for curr in "${keep[@]}"; do [[ "${name}" =~ ^"${curr}" ]] && return 0; done
    return 1
  }

  find "${source}" -maxdepth 1 -iname "*.tbz" -print | \
    while read -re path
    do

      name=$( basename "${path}" )

      if ! keep_file "${name}"
      then 
        logline "${path}" >> "${lastbup}"
        echo "rm -f '${path}'"
        rm -f "${path}"
      fi

    done

  if [[ -n ${DEBUG} ]] && [[ ${DEBUG} != "0" ]]
  then
    echo "daily:"
    for name in "${daily[@]}"
    do
      echo "  ${name}"
    done

    echo "weekly:"
    for name in "${weekly[@]}"
    do
      echo "  ${name}"
    done

    echo "monthly:"
    for name in "${monthly[@]}"
    do
      echo "  ${name}"
    done

    echo "all:"
    for name in "${keep[@]}"
    do
      echo "  ${name}"
    done
  fi

else

  cat <<USAGE
usage:
        bash $0 <backup-dir> <curr-datetime>
USAGE
  exit 255

fi

