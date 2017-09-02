#!/usr/bin/env bash
set -e

function check_dependencies() {
    local RED='\033[1;31m'
    local NC='\033[0m'
    local msg=''

    if [[ "$APP_ENV" != "testing" ]]; then
        for cmd in "jq" "xsel" "certutil" "NetworkManager"; do
            local str=''

            if ! [[ -x "$(command -v $cmd)" ]]; then
                printf -v str " - %s\n" "$cmd"
                local msg+="$str"
            fi
        done

        if [[ $msg != '' ]]; then
            printf "${RED}You have missing Valet dependiencies:\n"
            printf "$msg"
            printf "\nPlease refer to https://cpriego.github.io/valet-linux/requirements on how to install them.${NC}\n"
            exit 1;
        fi
    fi
}

# Determine if the port config key exists, if not, create it
function fix-config() {
    local CONFIG="$HOME/.valet/config.json"

    if [[ -f $CONFIG ]]
    then
        local PORT=$(jq -r ".port" "$CONFIG")

        if [[ "$PORT" = "null" ]]
        then
            echo "Fixing valet config file..."
            CONTENTS=$(jq '. + {port: "80"}' "$CONFIG")
            echo -n $CONTENTS >| "$CONFIG"
        fi
    fi
}

if [[ "$1" = "update" ]]
then
    check_dependencies
    composer global update "cpriego/valet-linux"
    valet install
fi

check_dependencies
fix-config
