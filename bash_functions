################################################################################
#
#  file: ${HOME}/.bash_functions
#
#  date: 03/18/2013
#
#  auth: Andrew Shultzabarger
#
#  desc: utility functions for system commands and bash sessions
#
################################################################################


function escape
{
  args="$@"
  printf "$args" | sed -e "s/'/'\\\\''/g; 1s/^/'/; \$s/\$/'/"
}

function manbuiltin # easy access to bash built-ins
{
  man bash | less -p "^ {4,7}$1 "
  #help $1 # another potential doc source
}

function strmunge
{
  if ! echo "${1}" | \grep -Eq "(^|:)${2}($|:)"
  then
    if [[ "${3}" = "after" ]]
    then
      echo "${1}:${2}"
    else
      echo "${2}:${1}"
    fi
  else
    echo "${1}"
  fi
}

function useshopt
{
  isset=$( shopt "${1}" > /dev/null ; printf $? )
  shopt -s "${1}" ; "${@:2}"
  [[ 1 == "${isset}" ]] && shopt -u "${1}"
}

function ignorecase
{
  useshopt "nocasematch" "$@"
}

function uc
{
  if [[ $# -gt 0 ]]
  then
    tr '[:lower:]' '[:upper:]' <<<"$@"
  fi
}

function lc
{
  if [[ $# -gt 0 ]]
  then
    tr '[:upper:]' '[:lower:]' <<<"$@"
  fi
}

function nullglob
{
  useshopt "nullglob" "$@"
}

function streq
{
  if [[ ${#1} -eq ${#2} ]] && [[ $1 == $2 ]] ; then
    echo $TRUE ;
  else
    echo $FALSE ;
  fi
}

function streqi
{
  ignorecase streq "$@"
}

function silent
{
  [[ $# -gt 0 ]] && "$@" &> /dev/null
}

function silentout
{
  [[ $# -gt 0 ]] && "$@" 1> /dev/null
}

function silenterr
{
  [[ $# -gt 0 ]] && "$@" 2> /dev/null
}

function rmtrailing
{
  if [[ ${#} -gt 1 ]]
  then
    shopt -s extglob
    echo "${1%%+(${2})}"
  fi
}

function rmtrailingslashes
{
  if [[ ${#} -gt 0 ]]
  then
    rmtrailing "${1}" '/'
  fi
}

function dos2unix
{
  if type -P dos2unix > /dev/null
  then
    command dos2unix "$@"
  else
    perl -pi -e 's/\r\n|\n|\r/\n/g' "$@"
  fi
}

function unix2dos
{
  if type -P unix2dos > /dev/null
  then
    command unix2dos "$@"
  else
    perl -pi -e 's/\r\n|\n|\r/\r\n/g' "$@"
  fi
}

function lineat
{
  # prints the N'th line of each file specified, prefixed by the
  #  filename if more than one file
  for file in "${@:2}"
  do
    [[ $# -gt 2 ]] && printf "${file}:"
    perl -ne "${1} == $. and print and exit" "${file}"
  done
}

function lineof
{
  args=()
  case=

  # poor man's option parsing
  while test $# -gt 0
  do
    case "${1}" in
      (-i) case=i ;;
      ( *) args=("${args[@]}" "${1}") ;;
    esac
    shift
  done

  # prints the line number(s) containing a given pattern in each file
  #  specified, prefixed by the filename if more than one file
  for curr in "${args[@]:1}"
  do
    code="/${args[0]}/${case} and print $..$/"
    if [[ ${#args[@]} -gt 2 ]]
    then
      for line in $( perl -ne "${code}" "${curr}" )
      do
        echo "${curr}:${line}"
      done
    else
      perl -ne "${code}" "${curr}"
    fi
  done
}

function perlprof
{
  #
  # this function uses module Devel::NYTProf to generate profiling statistics for perl programs
  #
  # simply use 'perlprof' in place of 'perl' when invoking the interpreter, and a corresponding
  # output file "./<basename of script>-nytprof.out" will be generated. the options below will
  # control various behaviors and features of the generated output file.
  #
  # once the profile has been generated, there are various tools to process the output file
  # for evaluation (each with their own man page):
  #
  #  nytprofhtml  - (main processor) generates fully cross-referenced HTML reports
  #  nytprofcalls - processes the call events
  #  nytprofcg    - translates into a format for KCachegrind
  #  nytprofcsv   - generates a report in CSV format
  #  nytprofmerge - reads multiple NYTProf output files and outputs a merged one
  #  nytprofpf    - generates a report for plat_forms
  #
  # by default, this function will process the output file through nytprofhtml into a directory
  # with a name similar to the output file (according to the options below). creates the
  # directory if needed, and deletes any preexisting contents otherwise.
  #

  # see section NYTPROF ENVIRONMENT VARIABLE in perldoc Devel::NYTProf
  file_pid=1 # addpid
  file_timestamp=1 # addtimestamp
  file_savesrc=0 # savesrc
  file_compress=0 # compress
  out_trace=0 # trace
  prof_start=begin # start
  #prof_start=init # start
  prof_optimize=0 # optimize # disable the perl (source code) optimizer for more accurate line references
  prof_subs=1 # subs
  prof_blocks=1 # blocks
  prof_statements=1 # stmts
  prof_slowops=2 # slowops
  prof_sigexit="int,hup,abrt,kill,quit,segv,term" # sigexit # see kill -l for list
  prof_forkdepth=-1 # forkdepth # -1 is unlimited depth
  prof_clock=6 # clock # CLOCK_MONOTONIC # for definitions, see:  grep -r 'define *CLOCK_' /usr/include

  file_name="" # file

  output_dir="."
  output_suffix="-nytprof.out"
  for word in $@
  do
    file_bname=$(basename "${word}")
    perl -ne 'print; /^-\S*e\S*$/ and exit 1' <<<"${word}"
    [[ $? == 1 ]] && file_name="${output_dir}/inline${output_suffix}" && break
    [[ -f $word ]] && file_name="${output_dir}/${file_bname}${output_suffix}" && break
  done

  export NYTPROF="addpid=${file_pid}:addtimestamp=${file_timestamp}:savesrc=${file_savesrc}:compress=${file_compress}:trace=${out_trace}:start=${prof_start}:optimize=${prof_optimize}:subs=${prof_subs}:blocks=${prof_blocks}:stmts=${prof_statements}:slowops=${prof_slowops}:sigexit=${prof_sigexit}:forkdepth=${prof_forkdepth}:clock=${prof_clock}:file=${file_name}"

  PERL5OPT="-d:NYTProf" perl $@

  profile=$(ls -t "${file_name}"* | head -n 1)

  if [[ -f "${profile}" ]]
  then
    output=${output_dir}/$(basename "${file_name}" | sed -e "s/${output_suffix}.*/${output_suffix}/")
    nytprofhtml --file "${profile}" --out "${output}" --delete
  else
    echo "error creating report: no such profile: ${profile}"
  fi
}

function tree
{
  if type -P tree > /dev/null
  then
    command tree "$@"
  else
    path="."
    [[ -n ${1} ]] && path="${1}"
    find "${path}" | sed -e 's;[^/]*/;|____;g' -e 's;____|;  |;g'
  fi
}

function pathadd
{
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]
  then
    PATH="$1:${PATH}"
  fi
}

function now_long
{
  date +"${DATETIME_FORMAT_LONG}"
}

function now
{
  date +"${DATETIME_FORMAT}"
}

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

function tgzbackup
{
  if [[ ${#} -gt 0 ]]
  then
    if [[ -d ${1} ]]
    then
      SOURCE=`rmtrailingslashes "${1}"`
      TARGET="${SOURCE}__`now`.tgz"
      echo "[+] compressing \"${1}\" to \"${TARGET}\""
      tar -czvf "${TARGET}" "${SOURCE}"
    else
      echo "error: input must be a directory"
    fi
  fi
}

function tbzbackup
{
  if [[ ${#} -gt 0 ]]
  then
    if [[ -d ${1} ]]
    then
      SOURCE=`rmtrailingslashes "${1}"`
      TARGET="${SOURCE}__`now`.tbz"
      echo "[+] compressing \"${1}\" to \"${TARGET}\""
      tar -cjvf "${TARGET}" "${SOURCE}"
    else
      echo "error: input must be a directory"
    fi
  fi
}

function zipbackup
{
  if [[ ${#} -gt 0 ]]
  then
    if [[ -d ${1} ]]
    then
      SOURCE=`rmtrailingslashes "${1}"`
      TARGET="${SOURCE}__`now`.zip"
      echo "[+] compressing \"${SOURCE}\" to \"${TARGET}\""
      zip -r "${TARGET}" "${SOURCE}"
    else
      echo "error: input must be a directory"
    fi
  fi
}

function backup
{
  if [[ ${#} -gt 0 ]]
  then
    SOURCE=`rmtrailingslashes "${1}"`
    TARGET="${SOURCE}__`now`"
    echo "[+] copying \"${1}\" to \"${TARGET}\""
    cp -r "${SOURCE}" "${TARGET}"
  fi
}

function stamp
{
  if [[ $# -gt 0 ]]
  then
    SOURCE=`rmtrailingslashes "${1}"`
    TARGET="${SOURCE}__`now`"
    mv "${SOURCE}" "${TARGET}"
    echo "${TARGET}"
  fi
}

function stamp_unixtime
{
  if [[ $# -gt 0 ]]
  then
    SOURCE=`rmtrailingslashes "${1}"`
    TARGET="${SOURCE}".`date "+%s"`
    mv "${SOURCE}" "${TARGET}"
    echo "${TARGET}"
  fi
}

function quiet_nohup
{
  if [[ $# = 0 || -z $@ ]]
  then
    echo "error: quiet_nohup: no command"
  else
    nohup "$@" > /dev/null 2>&1 &
  fi
}

function absdirpath # absolute directory path to file/dir
{
  if [[ $# > 0 ]]
  then
    RELATIVE_PATH=${1}
    if [[ ! -d "${RELATIVE_PATH}" ]]
    then
      RELATIVE_PATH=$( dirname "${RELATIVE_PATH}" )
    fi
    echo $( cd "${RELATIVE_PATH}" ; pwd -P )
  fi
}

function touchsz
{
  if [[ $# -ge 3 ]]
  then
    file=$1
    size=$2
    sdev=$3
    if [[ ! -f "${file}" ]]
    then
      if [[ "${size}" =~ ^[0-9]{1,10}$ ]]
      then
        # dd does not support block sizes greater than 4GiB, so you must
        # use some arithmetic combining options bs and count, which is
        # too complex for the purpose of this function, so do it yourself
        if [[ ${size} -le $(( 4 * $GiB_BYTES )) ]]
        then
          if [[ "${sdev}" =~ ^z(e(r(o)?)?)?$ ]]
          then
            dev="/dev/zero"
          elif [[ "${sdev}" =~ ^r(a(n(d(o(m)?)?)?)?)?$ ]]
          then
            dev="/dev/urandom"
          else
            echo "error: invalid source device selection: ${sdev}"
            return 4
          fi

          dd if="${dev}" of="${file}" bs=${size} count=1

        else
          echo "error: size cannot be greater than 4GiB"
          return 3
        fi
      else
        echo "error: invalid size: ${size}"
        return 2
      fi
    else
      echo "error: file exists: ${file}"
      return 1
    fi
  else
    echo "creates new <file> of <size> bytes, initialized with <zero|random>"
    printf "usage:\n\t${FUNCNAME[0]} <file> <size> <zero|random>\n"
    return 255
  fi
}

function findfatties
{
  DIR=''
  if [[ ${#} -gt 0 ]]
  then
    DIR=`rmtrailingslashes "${1}"`
  fi

  if [[ -d "${DIR}" ]]
  then
    find "${DIR}" -type f -exec stat -f "%z%t%N" {} \+ | sort -nr
  else
    echo "error: findfatties: not a directory: ${DIR}"
  fi
}

function proxy_set_HOST
{
  __proxy_host__='HOST:80'

  export http_proxy="http://$__proxy_host__"
  export HTTP_PROXY="http://$__proxy_host__"
  export https_proxy="https://$__proxy_host__"
  export HTTPS_PROXY="https://$__proxy_host__"

  unset __proxy_host__
  unset no_proxy
}

function proxy_unset_all
{
  __proxy_host__='localhost,127.0.0.0/8,*.local'

  export no_proxy="$__proxy_host__"

  unset __proxy_host__
  unset http_proxy
  unset HTTP_PROXY
  unset https_proxy
  unset HTTPS_PROXY
}

function cdiff
{
  if [[ ${#} -gt 1 ]]
  then
    colordiff -yW"`tput cols`" "${1}" "${2}"
  else
    echo 'error: missing input'
  fi
}

function usbdevices
{
  # OS X only
  system_profiler SPUSBDataType | sed -ne '/USB Flash Drive/,$p' | sed -ne '/Volumes/,$p' | grep 'Mount Point' | sed -e 's/^ *Mount Point: //'
}

function screen.rpi
{
  devuart=/dev/cu.SLAB_USBtoUART
  baud=115200

  devexists=0
  while [[ ${devexists} -eq 0 ]]
  do
    ls "${devuart}" >/dev/null 2>&1
    [[ $? -eq 0 ]] && devexists=1
  done

  [[ ${devexists} ]] && screen "${devuart}" "${baud}"
}

function expose-sdcard
{
  if [[ $# -lt 2 ]]
  then
    cat <<USAGE
usage: $0 </dev/sdcard> </output/file.vmdk>
USAGE
  else 
    disk=${1}
    vmdk=${2}
    user=$(whoami)

    if [[ -f "${disk}" ]]
    then
      if [[ -f "${vmdk}" ]]
      then
        echo "notice: deleting existing virtual disk file: ${vmdk}"
        sudo rm "${vmdk}"
      fi
      
      sudo diskutil unmountDisk "${disk}"
      sudo VBoxManage internalcommands createrawvmdk -filename "${vmdk}" -rawdisk "${disk}"
      sudo chown "${user}" "${vmdk}"
      sudo chown "${user}" "${disk}"

      echo "VirtualBox hard disk created for ${user}: ${vmdk}"

    else
      echo "error: SD card device not found: ${disk}"
    fi
  fi
}

function chmod-tree-rw
{
  fmode=644
  dmode=755

  args=("${@}")

  if [[ ${#} -lt 1 ]]
  then
    args=(".")
  fi

  for file in "${args[@]}"
  do
    if [[ -f "${file}" ]]
    then

      chmod ${fmode} "${file}"

    elif [[ -d "${file}" ]]
    then

      chmod ${dmode} "${file}"
      find "${file}" -type f -exec chmod ${fmode} {} \+
      find "${file}" -type d -exec chmod ${dmode} {} \+

    fi
  done
}

function eval-loop
{
  if [[ ${#} -gt 1 ]]
  then
    _IFS="${IFS}"
    IFS=$'\n'
    ${1} | while read -re s
    do
      eval ${2}
    done
    IFS="${_IFS}"
  else
    cat << 'USAGE'
  usage:
    eval-loop 'cmd-with-output' 'expression $s'

  example to find all files below CWD whose output from ``file'' contains "dynamically linked":
    eval-loop 'find . -type f' '[[ $(file "$s") == *"dynamically linked"* ]] || continue ; echo $s'

  example to unmount all USB mass storage devices using the ``usbdevices'' function in ~/.bashrc:
    eval-loop 'usbdevices' 'sudo diskutil umount "$s"'
USAGE
  fi
}

function writespeed
{
  if [[ $# -gt 0 ]]
  then

    file=$1
    path=$( dirname "${file}" )

    if [[ ! -d "${path}" ]]
    then
      mkdir -vp "${path}"
      [[ -d "${path}" ]] || return 1
    fi

    if [[ ! -w "${path}" ]]
    then
      echo "error: cannot write to directory: ${path}"
      return 2
    fi

    if [[ -d "${file}" ]]
    then
      echo "error: specified file is a directory: ${file}"
      return 3
    fi

    if [[ -f "${file}" ]] && [[ ! -w "${file}" ]]
    then
      echo "error: cannot overwrite file: ${file}"
      return 4
    fi

    repeat=0
    while [[ $repeat -eq 0 ]]
    do
      dd if=/dev/urandom of="${file}" bs=25M count=1 2>&1 |\
        grep -vP 'records (in|out)' |\
        sed -E 's/^.+,\s+([^,]+)$/\1/'
      repeat=$? # effectively traps a ctrl+c
    done

  else
    echo "error: no filename given"
    return 255
  fi
}

function chrome-tunnel
{
  user='andrew'
  host='192.168.2.1'
  port='8123'

  [[ ${#} -gt 0 ]] && user="${1}"
  [[ ${#} -gt 1 ]] && host="${2}"
  [[ ${#} -gt 2 ]] && port="${3}"

  proctag='local socks5 proxy'
  chromepath='google-chrome'

  ssh -fCND "0.0.0.0:${port}" "${user}"@"${host}" -- "${proctag}"

  "${chromepath}" --proxy-server="socks5://localhost:${port}"

  procpid=$(pgrep -f "${proctag}")

  if [[ ${#procpid} -gt 0 ]]
  then
    kill "${procpid}"
  else
    echo "error: cannot locate forked SSH tunnel process"
  fi
}

function windows-special-folder
{
  codemin=0
  codemax=255

  errfile=$(mktemp -t "winsferr-XXXX")

  if [[ $# -gt 0 ]]
  then
    cygpath -au -F "${1}"
  else
    for i in $( seq $codemin $codemax )
    do
      sfpath=$( cygpath -au -F $i 2>"${errfile}" )
      if [[ 0 -eq $( stat -c"%s" "${errfile}" ) ]]
      then
        printf "[%3d] %s\n" "$i" "$sfpath"
      fi
    done
  fi

  rm "${errfile}"
}
