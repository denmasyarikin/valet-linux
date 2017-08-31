#!/usr/bin/env bash
set -e

function check_dependencies() {
    local RED='\033[1;31m'
    local NC='\033[0m'
    local BOOL=true

    for cmd in "jq" "xsel" "certutil" "NetworkManager"; do
        if ! [ -x "$(command -v $cmd)" ]; then
            printf "${RED}%-15s" "$cmd"
            printf "is missing, please install the program before proceeding.\n${NC}"
            local BOOL=false
        fi
    done

    if [ "$BOOL" = false ]; then
        exit 1;
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
