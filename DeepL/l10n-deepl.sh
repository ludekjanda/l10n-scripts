#!/bin/bash

# TODO - support for glossaries 
# add languages as parameters

#Define colors
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
SOURCE_LANG="en"

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
  echo -e "${RED}usage: ${program##*/} [-h|--help] [-f|--filename]${RESET}"
  echo -e ""
  echo -e "This program translates Docx through Deepl."
  echo -e ""
  echo -e "Example: \$ ${program##*/} -f \"app-reminder-EN.docx\""
}

runCommand() {

  echo "${GREEN}[INFO]    getting a list of glossaries from DeepL${RESET}"

  curl -X GET 'https://api.deepl.com/v2/glossaries' \
  --header 'Authorization: DeepL-Auth-Key '$DEEPL_AUTH_KEY > glossaries.json


  cp   glossaries.json      glossaries.json.tmp &&
  jq . glossaries.json.tmp >glossaries.json     &&
  rm   glossaries.json.tmp

  cat glossaries.json


for LANG in "${LANGS[@]}"
  do

   GLOSSARY_ID=$(  cat glossaries.json | jq -r --arg id "${LANG}" '.glossaries[] | select(.target_lang==$id).glossary_id')
    echo "${GREEN}[INFO]    Glossary id="$GLOSSARY_ID${RESET}
    echo "${GREEN}[INFO]    Target language="$LANG${RESET}
    echo "${GREEN}[INFO]    Source language="$SOURCE_LANG${RESET}
    if [ $SOURCE_LANG == "cs" ]; then
      echo "[INFO]    Source language "$SOURCE_LANG" does not support glossaries"
      curl -X POST 'https://api.deepl.com/v2/document' --header 'Authorization: DeepL-Auth-Key '$DEEPL_AUTH_KEY --form 'target_lang='${LANG} --form 'file=@'$FILENAME'.'$EXTENSION --form 'formality=prefer_less' --form 'source_lang='${SOURCE_LANG} --output response.json 
    else
      if [ $LANG == "fr" ]; then
        echo "${GREEN}[INFO]    Applying formal tone in French${RESET}"
        curl -X POST 'https://api.deepl.com/v2/document' --header 'Authorization: DeepL-Auth-Key '$DEEPL_AUTH_KEY --form 'target_lang='${LANG} --form 'file=@'$FILENAME'.'$EXTENSION --form 'formality=prefer_more' --form 'glossary_id='$GLOSSARY_ID --form 'source_lang='${SOURCE_LANG} --output response.json
      else
        curl -X POST 'https://api.deepl.com/v2/document' --header 'Authorization: DeepL-Auth-Key '$DEEPL_AUTH_KEY --form 'target_lang='${LANG} --form 'file=@'$FILENAME'.'$EXTENSION --form 'formality=prefer_less' --form 'glossary_id='$GLOSSARY_ID --form 'source_lang='${SOURCE_LANG} --output response.json 
      fi
    fi

    JSON="cat response.json"
    DOCUMENT_ID=($($JSON | jq -r '.document_id'))
    DOCUMENT_KEY=($($JSON | jq -r '.document_key'))

    echo "${GREEN}[INFO]    Document_ID="$DOCUMENT_ID
    echo "[INFO]    Document_KEY="$DOCUMENT_KEY

    echo "[INFO]    Checking status${RESET}"

    curl -X POST 'https://api.deepl.com/v2/document/'$DOCUMENT_ID \
    --header 'Authorization: DeepL-Auth-Key '$DEEPL_AUTH_KEY \
    --header 'Content-Type: application/json' \
    --data '{
    "document_key": "'$DOCUMENT_KEY'"
    }'

    echo -e "\n${GREEN}[INFO]    Waiting for 10s${RESET}"
    sleep 10

    curl -X POST 'https://api.deepl.com/v2/document/'$DOCUMENT_ID'/result' --header 'Authorization: DeepL-Auth-Key '$DEEPL_AUTH_KEY --header 'Content-Type: application/json' \
    --data '{
    "document_key": "'$DOCUMENT_KEY'"
    }' > $FILENAME-$LANG.$EXTENSION

    rm response.json
done

 rm glossaries.json

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
    -f|--filename)
    FILENAME="$2"
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

if [[ -z $FILENAME ]]; then
    help
    exit 0
fi

FILENAME=$(basename -- "$FILENAME")
EXTENSION="${FILENAME##*.}"
FILENAME="${FILENAME%.*}"

if [ ! -e "$FILENAME.$EXTENSION" ]; then
    echo -e "${RED}[ERROR]      File does not exist!${RESET}"
    exit 0
fi 

#declare -a  LANGS=("ES" "PT-BR" "IT" "NL" "HU" "FR" "PL" "HU" "NB")

declare -a LANGS=("")

echo "  1) CS > SK"
echo "  2) EN > All except CS, SK"
echo "  3) EN > All including SK, exc. CS"
echo "  4) EN > CS"
echo "  5) CS > EN"
read n
case $n in
        1) 
          declare -a LANGS=("sk")
          SOURCE_LANG="cs"
          ;;
        2) declare -a  LANGS=("da" "es" "fi" "pt-br" "it" "nl" "hu" "fr" "pl" "nb" "sv")
          SOURCE_LANG="en"
          ;;
        3) declare -a  LANGS=("da" "es" "fi" "pt-br" "it" "nl" "hu" "fr" "pl" "nb" "sk" "sv")
          SOURCE_LANG="en"
          ;;
        4) declare -a  LANGS=("cs")
          SOURCE_LANG="en"
          ;;
        5) declare -a  LANGS=("en")
          SOURCE_LANG="cs"
          ;;
        *) echo "invalid option";;
esac

runCommand

