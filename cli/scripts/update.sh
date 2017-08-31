#!/usr/bin/env bash
set -e

function check_dependencies {
    local RED='\033[1;31m'
    local NC='\033[0m'
    local BOOL=true

    for cmd in "jq" "xsel" "certutil" "NetworkManager"; do
        if ! [ -x "$(command -v $cmd)" ]; then
            printf "${RED}%-15s" "$cmd"
            printf "missing, please install the program.\n${NC}"
            BOOL=false
        fi
    done

    if [ "$BOOL" = "false" ]; then
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

function cleanup {
    local NM="/etc/NetworkManager"
    local TMP="/tmp/nm.conf"

    if [[ -f "$NM"/dnsmasq.d/valet ]]
    then
        echo "Removing old dnsmasq config file..."
        sudo rm "$NM"/dnsmasq.d/valet
    fi

    if [[ -f "$NM"/conf.d/valet.conf ]]
    then
        echo "Removing old NetworkManager config file..."
        sudo rm "$NM"/conf.d/valet.conf
    fi

    if grep -xq "dns=dnsmasq" "$NM/NetworkManager.conf"
    then
        echo "Removing dnsmasq control from NetworkManager..."
        sudo grep -v "dns=dnsmasq" "$NM/NetworkManager.conf" > "$TMP" && sudo mv "$TMP" "$NM/NetworkManager.conf"
    fi

    echo "Cleanup done."
}

if [[ "$1" = "update" ]]
then
    check_dependencies
    composer global update "cpriego/valet-linux"
    valet install
fi

check_dependencies
fix-config
# cleanup
