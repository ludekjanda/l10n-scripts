#!/bin/bash

#Define colors
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
SPACE_ID="97382"
SOURCE_LANG="en"
unset $STORY_ID


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
  echo -e "${RED}usage: ${program##*/} [-f|--filename] [-h|--help] ${RESET}"
  echo -e ""
  echo -e "This script lists all JSON files in the current folder and imports them all into Storyblok based on the parameters in the filenames."
  echo -e ""
  echo -e "Example: \$ ${program##*/}"
}

runCommand() {

touch filenames.tsv
rm filenames.tsv
touch filenames.tsv

echo "${GREEN}[INFO]   Generating a list of files...${RESET} "

re='^(.*)\-([0-9]+).*$'
for f in *.json; do 
  [[ $f =~ $re ]] && printf $f'\t%s\t%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" >> filenames.tsv
done

#Check if the file exists
echo "${GREEN}[INFO]   The file filenames.tsv was generated.${RESET} "

echo "${GREEN}[INFO]   Converting pt to pt-br language codes to fit Storyblok standard${RESET} "

sed -e "s|\tpt\t|\tpt-br\t|g" filenames.tsv > filenames_fixed.tsv
rm filenames.tsv
mv filenames_fixed.tsv filenames.tsv

cat filenames.tsv

read -p "Continue (y/n)?" CHOICE
case "$CHOICE" in 
  y|Y ) 
  echo "yes"
  ;;
  n|N ) 
  echo "no"
  exit 1
  ;;
  * ) 
  echo "invalid"
  exit 1
  ;;
esac





echo "${GREEN}[INFO]   Parsing... ${RESET}"



while read -r FILENAME LANGUAGE_CODE STORY_ID ; do 
    echo "filename=$FILENAME language=$LANGUAGE_CODE story=$STORY_ID " 
    JSON=$(jq -Rs '{ "data": . }' < $FILENAME)
echo $JSON 


echo -e "\n"
echo "${GREEN}[INFO]   File $FILENAME into $LANGUAGE_CODE...${RESET}"
echo -e "\n\n"
curl -s -X PUT "https://mapi.storyblok.com/v1/spaces/${SPACE_ID}/stories/${STORY_ID}/import.json?lang_code=${LANGUAGE_CODE}" -H "Authorization: $SB_AUTH_KEY" --header "Content-Type: application/json" --data "${JSON}"

done < filenames.tsv

rm filenames.tsv


    

}



program=${0}

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -h|--help)
        help
        exit 0
    ;;
    *)    # unknown option
    ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

runCommand
