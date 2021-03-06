#!/bin/bash

BASE_DIR=`dirname $0`
SCRIPT_NAME=`basename $0`
SAVEDIR=""
LOG_FILE=""
URLS_LIST=""

CONF_FILE=${BASE_DIR}"/download_from_youtube.conf"
[ -f "$CONF_FILE" ] && source $CONF_FILE || {
 echo "Err: can not find conf file $CONF_FILE"
 exit 1
}

BEST_PROFILE=${AUTO_PROFILE:-"--no-progress --no-warnings -f best --restrict-filenames"}
WORST_PROFILE=${WORST_PROFILE:-"--no-progress --no-warnings -f worst --restrict-filenames"}
BESTAUDIO_PROFILE=${BESTAUDIO_PROFILE:-"--no-progress --no-warnings -f bestaudio --restrict-filenames"}
ASK_PROFILE=${ASK_PROFILE:-"--no-progress --no-warnings --restrict-filenames"}
YOUTUBEDL=${YOUTUBEDL:-"/usr/local/bin/youtube-dl"}
SCRIPT=${SCRIPT:-$BASE_DIR"/script2execute.sh"}
LINES_LIMIT=${LINES_LIMIT:-"1000"}
DOP=${DOP:-2}
[ "$DOP" -gt "8" ] && DOP=8
#-- Subroutines --------------------------------------------------------------
output () {
 local v_msg=$1
 if [ ! -z "$LOG_FILE" ]
 then
  if [ -w "$LOG_FILE" -a -f "$LOG_FILE" ]
  then
   echo $v_msg | tee -a $LOG_FILE
  else
   echo "(LFU) $v_msg"
  fi
 else
  echo $v_msg
 fi
}

function translit_file_name {
 local v_file_name=$1
# v_file_name=`echo -n "$v_file_name" | tr [\ ] [_]`
 v_file_name=`echo -n "$v_file_name" | sed "s/[\ \(\)]/\_/g"`
 extension="${v_file_name##*.}"
 TRS="${v_file_name%.*}"
 TRS=`echo $TRS | sed "y/абвгдезийклмнопрстуфхцы-/abvgdezijklmnoprstufxcy_/"`
 TRS=`echo $TRS | sed "y/АБВГДЕЗИЙКЛМНОПРСТУФХЦЫ/ABVGDEZIJKLMNOPRSTUFXCY/"`
 TRS=${TRS//ч/ch};
 TRS=${TRS//Ч/CH} TRS=${TRS//ш/sh};
 TRS=${TRS//Ш/SH} TRS=${TRS//ё/jo};
 TRS=${TRS//Ё/JO} TRS=${TRS//ж/zh};
 TRS=${TRS//Ж/ZH} TRS=${TRS//щ/sh\'};
 TRS=${TRS///SH\'} TRS=${TRS//э/je};
 TRS=${TRS//Э/JE} TRS=${TRS//ю/ju};
 TRS=${TRS//Ю/JU} TRS=${TRS//я/ja};
 TRS=${TRS//Я/JA} TRS=${TRS//ъ/\`};
 #TRS=${TRS//ъ\`} TRS=${TRS//ь/\'};
 TRS=${TRS//ъ/} TRS=${TRS//ь/};
 #TRS=${TRS//Ь/\'}
 TRS=${TRS//Ь/}
# TRS=${TRS//-/_}
 TRS=$(echo -e $TRS | iconv -f UTF-8 -t ASCII//TRANSLIT )
 TRS=${TRS//./}
 TRS=${TRS//,/}
 TRS=${TRS//\'/}
 TRS=$(echo -e $TRS | tr -d [\<\>\!\%])
 TRS=$(echo -e $TRS | tr [\ ] [\_])
 echo "${TRS}.${extension}" 
}

usage() {
cat << __EOFF__
Use: `basename $0` [options]...
See also config file, which name should be $CONF_FILE
-m|--mode	should be ASK|BEST|WORST|BAUDIO it's about type|quality of content which'll be downloaded;
		Default: BEST; Case insensitive;
-u|--urls	Should be double-quoted string of whitespace separated url, one or more url;
-d|--dop	Degree of parallelism of download; That is: how many download should be run simultaneously; 
		Maximum allowed value: 8; Default: 2;
-r|--retry	`basename $0` makes script-file with youtube-dl statements, for downloading video for you,
		by urls which you provide;
		In case youtube-dl download(s) hanged, while working, and you cancel it by ctrl-c or somehow, 
		you can ask `basename $0` to retry to execute the script-file with help of -r|--retry options;
##############################################################################################################
About parameter in config-file:
SAVEDIR		Folder for files of downloaded contents;
LOG_FILE	Full-path of log file;
DEBUG		1: do debug output; Any other value - do not debug output;
URLS_LIST	File with url, one url in one line
BEST_PROFILE	Set of youtube-dl for download content with best quality of media, f.e.: "--no-progress --no-warnings -f best --restrict-filenames"
WORST_PROFILE	Set of youtube-dl for download content with best quality of media, f.e.: "--no-progress --no-warnings -f worst --restrict-filenames"
YOUTUBEDL	Full-path to the youtube-dl utility
SCRIPT		Full-path to file where youtube-dl statement(s) will be placed
LINES_LIMIT	Limit for amount of string-lines in log file;
DOP		Degree of parallelism of download; That is: how many download should be run simultaneously;
		Maximum allowed value: 8; Default: 2;
__EOFF__
}

export download_func="downloadit () {
 output \"\$\$: \$1\";
 eval \"\$1\"
}"

retry() {
 echo "It's retry module"
 if [ -f "$SCRIPT" ]
 then
  if [ `cat $SCRIPT | wc -l` -gt "0" ]
  then
   echo "Well ok script, which is supposed to contain youtube-dl was found and it isn't empty;"
   echo "Try to execute it with default settings"
   cat $SCRIPT | xargs -n 1 -P $DOP -d "\n" -I {} bash -c 'echo $$; eval'\ \"\{\}\" | tee -a $LOG_FILE
  else
   echo "Script-file with youtube-dl calls was found as $SCRIPT but it empty;"
  fi
 else
  echo "Script-file with youtube-dl calls isn't found as $SCRIPT"
  echo "Nothing will be done"
 fi
}

#-- Main routine -----------------------------------------------------
v_module="main"

[ "$DEBUG" -eq "1" ] && output "$@"
options=$(getopt -o hm:u:d:r: -l help,mode:,urls:,dop:,retry: -- "$@")
if [ "$?" -ne 0 ]
then
 output "$module ERROR: Some error happened while arguments of script-call were parsed;"
 output "$module See help by ${SCRIPT_NAME} -h"
 exit 3
else
 [ "$DEBUG" -eq "1" ] && output "$module getopt output is: ${options}"
fi

eval set -- "$options"
MODE=""
URLS=""
while [ ! -z "$1" ]
do
 case "$1" in
  --) shift
      ;;
  -r|--retry) retry
	      ;;
  -h|--help) usage
             exit 0
             ;;
  -m|--mode) shift
             MODE=`echo -n "$1" | tr [:lower:] [:upper:]`
             [[ ! "$MODE" =~ ASK|BEST|WORST|BAUDIO ]] && { 
                                           output "incorrect value for -m|--mode arg; Use -h|--help for usage help;"
                                           exit 1
                                           }
             ;;
  -u|--urls) shift
             URLS="$1"
             ;;
  -d|--dop) shift
            DOP="$1"
            [[ ! "$DOP" =~ [0-9]+ ]] && {
                                         output "incorrect value for -d|--dop arg; Use -h|--help for usage help;"
                                         exit 1
                                        }
            [[ "$DOP" -gt "8" ]] && {
                                         output "Value for -d|--dop arg should be less than or equal 8; Use -h|--help for usage help;"
                                         DOP=8
                                      }
           ;;
  *) break ;;  
 esac
 shift
done

if [ ! -z "$LOG_FILE" ]
then
 v_rc="0"
 if [ ! -f "$LOG_FILE" ]
 then
  touch "$LOG_FILE" 1>/dev/null 2>&1
  v_rc=$?
 fi
 if [ "$v_rc" -ne "0" ]
 then
  echo "Err: log-file is setted to $LOG_FILE and it doesn't exist yet"
  echo "but it is not possible to create this file;"
  exit 1
 fi
fi

if [ ! -d "$SAVEDIR" ]
then
 output "Err: directory $SAVEDIR for saving downloaded file does not exists"
 exit 1
fi

if [ ! -f "$YOUTUBEDL" -a -x "$YOUTUBEDL" ]
then
 output "Err: path to youtube-dl utility is setted as ${YOUTUBEDL} but it isn't file and/or executable file"
 exit 1
fi

if [ -f "$SCRIPT" ] 
then
  cat /dev/null > $SCRIPT 1>/dev/null 2>&1
  v_rc=$?
else
  touch $SCRIPT 1>/dev/null 2>&1
  v_rc=$?  
fi
if [ "$v_rc" -ne "0" ]
then
 output "Err: cannot prepare file $SCRIPT (should be value of SCRIPT parameter in conf-file);"
 exit 1
fi

[ -z "$MODE" ] && MODE="BEST"
[ "$DEBUG" -eq "1" ] && output "MODE: $MODE; URLS: $URLS"

if [ -z "$URLS" ]
then
 output "cli-args of call doesn't contain one or more video-url in -u|--urls arg;"
 output "It is supposed that list of urls in file, mentioned as URLS_LIST in conf-file will be used;"
 output "URLS_LIST: $URLS_LIST"
 if [ ! -f "$URLS_LIST" ]
 then
  output "Err: but file with url-list doesn't setted or doesn't exist!"
  exit 1
 else
  output "Ok: files with url-list of video to download is setted as $URLS_LIST and it's a regular file;"
  URLS=`cat $URLS_LIST | sort -u`
 fi
else
 output "Ok, list of video's url is explicity setted"
fi

  output "List of urls are:"
  v_x=1
  for i in $URLS
  do
   output "${v_x} $i"
   v_x=$((v_x+1))
  done

output "DOP=$DOP"
#output "URLS=$URLS"
output "MODE=$MODE"
output "Processing list of urls"
v_x=1
for YOUTUBE_URL in $URLS
do
 v_format=""
 v_answer=""
 v_options=""
 output "${v_x} $YOUTUBE_URL"

 if [ "$MODE" == "ASK" ]
 then
  $YOUTUBEDL -F $YOUTUBE_URL | sed "s/^\[youtube\].*//g"
  read -p "Please choose a digint-code of format in which you want to get the content (0 for exit): " v_answer
  while [[ ! $v_answer =~ [0-9]+ ]]
  do
   read -p "Sorry by you have to choose a digint-code of format, value from first left column (0 for exit): " v_answer
  done
  if [ "$v_answer" -eq "0" ] 
  then
   output "Well, ok, thank you for your time, bye."
   exit 0
  else
   v_format="-f $v_answer"
  fi
 fi

 v_file_name=`$YOUTUBEDL ${v_format} --no-warnings --get-filename $YOUTUBE_URL`
 echo "==>${v_file_name}<=="
 v_file_name=`translit_file_name "$v_file_name"`
 echo "==>${SAVEDIR}"/"${v_file_name}<=="
 [ -f "${SAVEDIR}"/"${v_file_name}" ] && rm -f "${SAVEDIR}"/"${v_file_name}"

 case "$MODE" in
  "ASK") v_options=${ASK_PROFILE}" "${v_format};;
  "BEST") v_options=${BEST_PROFILE};;
  "WORST") v_options=${WORST_PROFILE};;
  "BAUDIO") v_options=${BESTAUDIO_PROFILE};;
 esac

 echo "$YOUTUBEDL $v_options -o \"${SAVEDIR}"/"${v_file_name}\" $YOUTUBE_URL" | tee -a $SCRIPT

 v_x=$((v_x+1))
done

#cat $SCRIPT
#exit 0
#declare -p 
cat $SCRIPT | xargs -n 1 -P $DOP -d "\n" -I {} bash -c 'echo $$; eval'\ \"\{\}\" | tee -a $LOG_FILE

#chmod u+x $SCRIPT
#$SCRIPT | tee -a $LOG_FILE

LINES_COUNT=`cat $LOG_FILE | wc -l`
if [ "$LINES_COUNT" -gt "$LINES_LIMIT" ]
then
        LINES_COUNT=`echo $LINES_COUNT $LINES_LIMIT | awk '{x=$1-$2; printf "%d", x;}'`
        sed -i "1,${LINES_COUNT}d" $LOG_FILE
fi




