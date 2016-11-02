#!/bin/bash

set -u
#set -e

EFFSCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
MY_DIR="$(dirname "${EFFSCRIPT}")"

CREDENTIALS="${MY_DIR}/credentials"

if [ -f "${CREDENTIALS}" ]; then
    source "$CREDENTIALS"
else
    echo "Credentials file '${CREDENTIALS}' not found. Exiting."
    exit 1
fi

IHELPER_ROOT_URL="https://ihelper-prp.mts.com.ua/SelfCare"
UA="${UA:-Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36}" 

ROTATE_SIZE=${ROTATE_SIZE:-10}

function usage {
    echo
    echo "Print balances for ukrainian mobile profiver MTS/Vodafone"
    echo "Just rename "$CREDENTIALS}.exmple" file to "$CREDENTIALS" in the script directory"
    echo "and fill it with numbers and passwords for mts-helper."
    echo 
    echo "Option: --dry-run to use previous obtained balances."
    echo 
    echo "Enjoy"
}

DRY_RUN=

while [ $# -gt 0 ]; do
    case "$1" in
  
       --help|-h|-\?)
            usage
            exit 0
            ;;

        --dry-run)
            DRY_RUN=1
            shift
            ;;

        --no-dry-run)
            shift
            ;;

        --)
            # Rest of command line arguments are non option arguments
            shift # Discard separator from list of arguments
            continue
            #break # Finish for loop
            ;;

        -*)
            echo "Unknown option: $1" >&2
            usage
            exit 2
            ;;

        *)
            echo "Not expected arguments: $1" >&2
            usage
            exit 2
            # finish parsing options
            #break
    esac
done



function rotate () {
    local FILE="$1"
    local MAX=${2:-90}

    local BODY="$(basename $FILE)"
    local DATA_DIR="$(dirname $FILE)"

    local ROTATE_FLAG=
    [ -e "${FILE}" ] && ROTATE_FLAG=1

    [ -n "${ROTATE_FLAG}" ] && {
      find "${DATA_DIR}" -maxdepth 1 -name ${BODY}\.\* \( -type d -or -type f \) -printf '%f\n' | sort -t '.' -k1 -nr | while read CF; do
        NUM=${CF##*\.}
        #NUM=$(echo ${NUM}|sed -e 's/^0*//g')
        #echo "Found: $CF NUM: $NUM" >&2
        printf -v NEWCF "${BODY}.%d" $((++NUM))
        if ((NUM<=MAX)); then
            [ -d "${DATA_DIR}/${NEWCF}" ] && {
                rm -rf "${DATA_DIR}/${NEWCF}"
            }
          mv "${DATA_DIR}/$CF" "${DATA_DIR}/${NEWCF}"
        else
          [ -e "${DATA_DIR}/$NEWCF" ] && rm -rf "${DATA_DIR}/${NEWCF}"
        fi
      done
      mv "${DATA_DIR}/$BODY"  "${DATA_DIR}/${BODY}.0"
    }
}


function get_data {
    local ACTION="$1"
    local TAG="$2"
    local METHOD="${3:-GET}"
    local PARAMS="${4:-}"

    local MARKER="${ACTION}-${TAG}"
    local INVOKE_DATA_DIR="${INVOKE_DIR}"

    local DUMP_HEADER="${INVOKE_DATA_DIR}/${MARKER}.headers"
    local DUMP_STDERR="${INVOKE_DATA_DIR}/${MARKER}.stderr"
    local OUTPUT="${INVOKE_DATA_DIR}/${MARKER}.output.html"

    local COOKIES_FILE="${INVOKE_DATA_DIR}/${TAG}.cookies.txt"
    local GET_COOKIES=
    local SET_COOKIES=
    if [ -f "${COOKIES_FILE}" ]; then
        GET_COOKIES="--cookie     ${COOKIES_FILE}"
    else
        SET_COOKIES="--cookie-jar ${COOKIES_FILE}"
    fi

    local URL="${IHELPER_ROOT_URL}/${ACTION}.aspx"

    echo "${URL}" > ${INVOKE_DATA_DIR}/${MARKER}.url

    CURL_CMD="curl \
                    --silent \
                    --verbose \
                    --location \
                    --request ${METHOD} \
                    --dump-header ${DUMP_HEADER} \
                    --stderr ${DUMP_STDERR} \
                    --output ${OUTPUT} \
                    ${UA:+ --user-agent \"${UA}\"} \
                    ${PARAMS:+ --data \"${PARAMS}\"} \
                    ${SET_COOKIES:-} \
                    ${GET_COOKIES:-} \
                    ${REFERER:+--referer ${REFERER}} \
                \"${URL}\""

   #echo eval "${CURL_CMD}"
   #exit 0
   #echo
   ((!DRY_RUN)) && eval "${CURL_CMD}"

    echo "${OUTPUT}"
}

## Body

DATA_DIR="${DATA_DIR:-${MY_DIR}/Data}"
INVOKE_DIR="${DATA_DIR}/invoke"
((! DRY_RUN)) && rotate "${INVOKE_DIR}" ${ROTATE_SIZE}
((! DRY_RUN)) && mkdir -p "${INVOKE_DIR}"
[ ! -d "${DATA_DIR}" -a ! "$DRY_RUN" ] && { echo dir will be created ;  mkdir ${DATA_DIR} ;}

#exit 0

echo
for ITEM in "${CREDENTIALS[@]}"; do
    #echo "key  : $ITEM"
    TMP="${ITEM}"
    NICK="${TMP%%:*}"; 
    TMP="${TMP#${NICK}:}"
    PHONE0="${TMP%%:*}"; 
    PHONE="${PHONE0//[^0-9]/}"
    PASSWORD="${TMP##*:}"

    #echo $NICK
    #echo $PHONE0
    #echo $PHONE
    #echo $PASSWORD

    REFERER="https://ihelper-prp.mts.com.ua/SelfCare/"
    POST_DATA=
    POST_DATA='__VIEWSTATE=%2FwEPDwUKMTc2ODk1NDA2Mw9kFgJmD2QWAgICDxYEHgVjbGFzcwUFbG9naW4eBmFjdGlvbgUUL1NlbGZDYXJlL2xvZ29uLmFzcHgWAgICD2QWBgIBDw8WAh4JTWF4TGVuZ3RoAglkZAIDDw8WAh4DS0VZBSFjdGwwMF9NYWluQ29udGVudF9jYXB0Y2hhNjMyMzg1MDlkZAIFDw8WBh4EVGV4dGUeCENzc0NsYXNzBQZzdWJtaXQeBF8hU0ICAmRkZPet9v%2Fu7wPl3aMO%2Fk46nFG8M5UD'
    POST_DATA="${POST_DATA}&__VIEWSTATEGENERATOR=6F2881C9"
    POST_DATA="${POST_DATA}&ctl00%24MainContent%24tbPhoneNumber=${PHONE}"
    POST_DATA="${POST_DATA}&ctl00%24MainContent%24tbPassword=${PASSWORD}"
    POST_DATA="${POST_DATA}&ctl00%24MainContent%24btnEnter=%D0%92%D0%BE%D0%B9%D1%82%D0%B8"
    TAG="${NICK}.${PHONE}"

    get_data 'logon'   "${TAG}" "POST" $POST_DATA > /dev/null
    DATA_FILE="$(get_data 'welcome' "${TAG}")"
    get_data 'logoff' $TAG > /dev/null
    DATA="$(cat "$DATA_FILE" )"
    TARIF="$(  echo "$DATA" | perl -ne '$_=$1, s/^\s*//, s/<.+?>//sg, print if m/Тарифный план:(.*)\n/';)"
    BALANCE="$(echo "$DATA" | perl -ne 'print $1 if m/Баланс:.*>(.*)грн.*/';)"
    printf "%15s  0%s %8suah   %s\n"  $NICK "$PHONE0" "$BALANCE" "${TARIF}"
done
echo

