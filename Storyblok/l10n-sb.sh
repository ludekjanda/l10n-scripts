#!/bin/bash

#Define colors
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
FILENAME="blog-en.xml"
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
  echo -e "${RED}usage: ${program##*/} [-|--id] [-h|--help] ${RESET}"
  echo -e ""
  echo -e "This program translates Storyblok articles without the wysiwyg block."
  echo -e ""
  echo -e "Example: \$ ${program##*/} -i \"432711270\""
}

runCommand() {

  echo "${GREEN}[INFO]    getting a list of glossaries from DeepL${RESET}"

  curl -X GET 'https://api.deepl.com/v2/glossaries' \
  --header 'Authorization: DeepL-Auth-Key '$DEEPL_AUTH_KEY > glossaries.json


  cp   glossaries.json      glossaries.json.tmp &&
  jq . glossaries.json.tmp >glossaries.json     &&
  rm   glossaries.json.tmp

  cat glossaries.json

  curl -X GET 'https://mapi.storyblok.com/v1/spaces/'${SPACE_ID}'/stories/'${STORY_ID}'/export.xml?lang_code='${SOURCE_LANG}'&export_lang=true' --header 'Authorization: '$SB_AUTH_KEY'' > "$FILENAME"

  cat ${FILENAME}

  xmlstarlet ed -L -d '//tag[contains(@id,"richtext:content")]' "$FILENAME"

  cat "$FILENAME" | xq -x //text > temp.txt

  i=0
  echo "${GREEN}[INFO]    Parsing fetched source${RESET}"
  while read line 
  do
    OLD_TEXTS[$i]="$line"
    echo "${GREEN}[INFO]    Hodnota:" $line
    i=$((i+1))

  done < temp.txt
  echo "${RESET}"
  rm temp.txt

  for LANG in "${LANGS[@]}"
    do
      new_texts=( )
      GLOSSARY_ID=$(  cat glossaries.json | jq -r --arg id "${LANG}" '.glossaries[] | select(.target_lang==$id).glossary_id')
      if [[ -z "$name" ]]; then
        echo "${GREEN}[INFO]    No glossary for this language${RESET}"
      else
        echo "${GREEN}[INFO]    Glossary id is "$GLOSSARY_ID${RESET}
      fi

      if [ $LANG = "fr" ]; then
        for name in "${OLD_TEXTS[@]}"; do
          curl -s -X POST 'https://api.deepl.com/v2/translate' --header 'Authorization: DeepL-Auth-Key '$DEEPL_AUTH_KEY \
          --data-urlencode text="$name" \
          --data-urlencode 'target_lang='${LANG} \
          --data-urlencode 'source_lang='${SOURCE_LANG} \
          --data-urlencode 'formality=prefer_more' \
          --data-urlencode 'glossary_id: '$GLOSSARY_ID \
          > temp.json
          echo "${GREEN}[INFO]    French needs to be more formal${RESET}"
          new_value=$(jq -r '.[] | .[] | .text' temp.json)
          echo $new_value
          new_texts+=( "${new_value}" )
          rm temp.json
        done
      else
        for name in "${OLD_TEXTS[@]}"; do
          curl -s -X POST 'https://api.deepl.com/v2/translate' --header 'Authorization: DeepL-Auth-Key '$DEEPL_AUTH_KEY \
          --data-urlencode text="$name" \
          --data-urlencode 'target_lang='${LANG} \
          --data-urlencode 'source_lang='${SOURCE_LANG} \
          --data-urlencode 'formality=prefer_less' \
          --data-urlencode 'glossary_id: '$GLOSSARY_ID \
          > temp.json
          new_value=$(jq -r '.[] | .[] | .text' temp.json)
          echo $new_value
          new_texts+=( "${new_value}" )
          rm temp.json
        done
      fi


    update_command=( xmlstarlet ed )
    for idx in ${!new_texts[@]}; do
      update_command+=(
        -u "//tag[$((idx + 1))]/text" # XPath uses 1-indexed values
        -v "${new_texts["$idx"]}"           # ...whereas bash arrays are 0-indexed
      )
      #echo $idx
      #echo ${new_texts[$idx]}

    done

    tempfile=$(mktemp "$FILENAME.XXXXXX")
    "${update_command[@]}" <"$FILENAME" >"$tempfile" && mv "$tempfile" blog-${LANG}.xml
    XML=$(jq -Rs '{ "data": . }' <blog-${LANG}.xml)
    echo ${XML} | jq .
    curl -s -X PUT "https://mapi.storyblok.com/v1/spaces/${SPACE_ID}/stories/${STORY_ID}/import.xml?lang_code=${LANG}" -H "Authorization: $SB_AUTH_KEY" --header "Content-Type: application/json" --data "${XML}"
    rm blog-${LANG}.xml
  done

  rm glossaries.json
  rm ${FILENAME}

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


echo "Machine translate to: "
echo "  1) CZ > SK"
echo "  2) EN > All except CZ, SK"
echo "  3) EN > All including SK, exc CZ"
echo "  4) EN > FR"
echo "  5) CS > EN"
read n
case $n in
  1) 
    declare -a LANGS=("sk")
    SOURCE_LANG="cs"
  ;;
  2) declare -a  LANGS=("da" "es" "fi" "pt-br" "it" "nl" "hu" "fr" "pl" "hu" "nb" "sv");;
  3) declare -a  LANGS=("da" "es" "fi" "pt-br" "it" "nl" "hu" "fr" "pl" "hu" "nb" "sk" "sv");;
  4) declare -a  LANGS=("fr");;
  5) 
    declare -a  LANGS=("en")
    SOURCE_LANG="cs"
  ;;
  *) echo "invalid option";;
esac

runCommand
