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
  . ~/.phraserc
fi

help() {
  echo -e "${RED}usage: ${program##*/} [-h|--help] [-p|--project] [-j|--job]${RESET}"
  echo -e ""
  echo -e "This program gets info about a job."
  echo -e ""
  echo -e "Example: \$ ${program##*/} -p \"sywxabq1wyNe1ASiyqqCxf\" -j \"0fBFa0hLOPEBxkXN31bgsk\""
}

runCommand() {

  URL="$(echo $PHRASE_URL'/api2/v1/projects/'$PROJECTID'/jobs/'$JOBID)"

  echo -e "\n"
  echo "[INFO]   Running $URL"
  echo -e "\n"

  curl --silent --location --request GET "$URL" \
          --header "Authorization: ApiToken "$PHRASE_TOKEN \
      --header 'Content-Type: application/json' 
  
  
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
    -j|--job)
    JOBID="$2"
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