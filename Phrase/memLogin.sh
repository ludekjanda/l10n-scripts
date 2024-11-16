#!/bin/bash

RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
PHRASE_URL='https://cloud.memsource.com/web'

help() {
   echo "usage: $program [-h|--help] [-c|--cleanup] [-d|--debug] [get-token]"
   echo "                [set-credentials]"
   echo ""
   echo "This program should use keyctl on Fedora and Keychain on Mac to store the user credentials. FIX YOUR CODE. "
   echo "This program issues Memsource token and saves it to ~/.phraserc."
   echo ""
   echo "Arguments:"
   echo "  -c|--cleanup  Runs cleanup of the credentials"
   echo "  -d|--debug    Enable debug"
   echo "  -h|--help     Displays this help"
   echo ""
   echo "Options:"
   echo "  set-credentials  Configures username and password in keychain"
   echo "  get-token        Get the token from Memsource API"
   echo ""
}


set_credentials() {
   echo "[INFO]    This feature is not implemented."
}

cleanup() {
   echo "[INFO]    This feature is not implemented."
}

get_token() {
  . ~/.phraserc
  echo -e "${GREEN}[INFO]    Getting token for this session${RESET}"
  echo -e "${RED}[WARNING]    Your passwords can be captured via monitoring the ps command. Fix your code ASAP${RESET}" 
  URL="$(echo ${PHRASE_URL}'/api2/v1/auth/login')"
  RESPONSE=($(curl -s --location POST ${URL} \
    --header 'Content-Type: application/json' \
    --data-raw '{"userName":"'$PHRASE_USERNAME'","password":"'$PHRASE_PASSWORD'"}' | jq -r '.token'))
  sed -i -e 's/PHRASE_TOKEN.*/PHRASE_TOKEN='$RESPONSE'/' ~/.phraserc
  echo "${GREEN}[INFO]    Got a new token.${RESET}"
}

program=${0}

if [ $# -eq 0 ]
  then
  help
  exit 0
fi

while true
do
  case $1 in
    -h|--help) 
    help
    exit 0
    ;;
    -d|--debug)
    export verbose=1
    set -x
    ;;
    -c|--clean)
    cleanup
    exit 0
    ;;
    set-credentials)
    set_credentials
    exit 0
    ;;
    get-token)
    get_token
    exit 0
    ;;
    *)
    exit 1
    ;;
  esac
shift
done