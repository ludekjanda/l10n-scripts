#!/bin/bash

#Define colors
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
SPACE_ID=""
SOURCE_LANG="en"
unset $STORY_ID
unset $LANGS

echo "${GREEN}[INFO]    Checking credentials${RESET}"

if [ -f ${HOME}/.l10nrc ]; then
  . ~/.l10nrc
else
  echo "You need to configure your localization credentials in ~/.l10nrc\n"
  echo "Edit file with vi ~/.l10nrc and paste following content:\n"
  echo "export DEEPL_AUTH_KEY=deepl auth key\n"
  echo "export SB_AUTH_KEY=storyblok auth key\n"
  exit 1
fi

help() {
  echo -e "${RED}usage: ${program##*/} [-i|--id] [-h|--help] ${RESET}"
  echo -e ""
  echo -e "This script pull a JSON file from Storyblok for further translation. It removes the \"richtext\" field because its structure as embedded JSON is hard to process in TMS."
  echo -e ""
  echo -e "Example: \$ ${program##*/} -i \"432711270\""
}

runCommand() {

  FILENAME=${STORY_ID}.json
  curl -X GET 'https://mapi.storyblok.com/v1/spaces/'${SPACE_ID}'/stories/'${STORY_ID}'/export.json?lang_code='${SOURCE_LANG}'&export_lang=true' --header 'Authorization: '$SB_AUTH_KEY'' > "$FILENAME"
  echo "${GREEN}[INFO]   The file ${FILENAME} was generated.${RESET} "
  echo -e "\n"
  echo "${GREEN}[INFO]   Removing the richtext part.${RESET} "
  jq 'del(.[keys[] | select(endswith("richtext:content"))])' ${FILENAME} > temp.json
  rm ${FILENAME}
  mv temp.json ${FILENAME}
  echo -e "\n"
  cat ${FILENAME}
  exit 1 
  

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
    -i|--id)
      STORY_ID="$2"
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

if [[ -z $STORY_ID ]]; then
  help
  exit 0
fi


echo "Source: "
echo "  1) EN"
echo "  2) CS"
read n
case $n in
  1) 
    SOURCE_LANG="en"
  ;;
  2) SOURCE_LANG="cs"
  ;;
  *) echo "invalid option";;
esac

runCommand
