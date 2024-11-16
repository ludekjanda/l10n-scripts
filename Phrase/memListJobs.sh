#!/bin/bash

#Define colors
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
PHRASE_URL='https://cloud.memsource.com/web'
JOBS=jobs.tsv

echo "${GREEN}[INFO]    Checking credentials${RESET}"

if [ -f ${HOME}/.phraserc ]; then
  . ~/.phraserc
else
  echo "You need to configure your Memsource credentials in ~/.memsourcerc\n"
  echo "Edit file with vi ~/.memsourcerc and paste following content:\n"
  echo "export MEMSOURCE_USERNAME=<username>\n"
  echo "export MEMSOURCE_PASSWORD=<password>\n"
  echo "export MEMSOURCE_TOKEN=<password>\n"
  exit 1
fi

URL="$(echo ${MEMSOURCE_URL}'/api2/v1/users?userName='$PHRASE_USERNAME)" 
RESPONSE=$(curl --header "Authorization: ApiToken "$PHRASE_TOKEN --write-out '%{http_code}' "$URL" --silent --output /dev/null)

if [[ "$RESPONSE" -ne 200 ]] ; then
  echo "${RED}[ERROR]    MEMSOURCE_TOKEN is unset. Need to login.${RESET}"
  memLogin.sh get-token
  . ~/.memsourcerc
fi

help() {
  echo -e "${RED}usage: ${program##*/} [-h|--help] [-p|--project]${RESET}"
  echo -e ""
  echo -e "This program lists projects filtered by name."
  echo -e ""
  echo -e "Example: \$ ${program##*/} -p \"sywxabq1wyNe1ASiyqqCxf\""
}

runCommand() {

  if [ -f "$JOBS" ]; then
    echo "${GREEN}[INFO]    Removing previous $JOBS${RESET}"
    rm $JOBS
  fi
    
  echo "${GREEN}[INFO]    Creating a new list of jobs${RESET}"

  URL="$(echo $PHRASE_URL'/api2/v1/projects/'$PROJECTID'/jobs')"

  TOTAL_PAGES=($(curl --silent --location --request GET "$URL" \
      --header "Authorization: ApiToken "$PHRASE_TOKEN \
    --header 'Content-Type: application/json' | jq -r '.totalPages|tonumber'))
	echo "${GREEN}[INFO]    Pages: " $TOTAL_PAGES " ${RESET}"
  let TOTAL_PAGES=TOTAL_PAGES-1
  x=0
  while [ $x -le $TOTAL_PAGES ]
    do
    URL="$(echo $PHRASE_URL'/api2/v1/projects/'$PROJECTID'/jobs?pageNumber='$x)"
    curl --silent --location --request GET "$URL" \
          --header "Authorization: ApiToken "$PHRASE_TOKEN \
      --header 'Content-Type: application/json' | jq -r '.content[] | [.filename,.uid] | @tsv ' >> jobs.tsv
    x=$(( $x + 1 ))
  
  done
  echo "${GREEN}[INFO]    A list of projects created at $JOBS ${RESET}"
}

program=${0}

if [ $# -eq 0 ];then
  help
  exit 0
fi


POSITIONAL=()
while [[ $# -gt 0 ]]
  do
  key="$1"
  case $key in
    -p|--project)
    PROJECTID="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ -z $PROJECTID ]]; then
    help
    exit 0
fi

runCommand