#!/bin/bash

# Terminate as soon as one command fails (e)
set -e

# Source .profile for extra path etc
if [ -f ~/.profile ]
then
    source ~/.profile
fi

# Go into repository workspace
cd $REPOSITORY

sudo mkdir -p /run/NetworkManager
echo 'nameserver 8.8.8.8' | sudo tee -a /run/NetworkManager/resolv.conf > /dev/null
echo 'user=root' | sudo tee -a /workspace/cli/stubs/dnsmasq.conf > /dev/null

# Install valet
./valet install

# Run Functional tests
./vendor/bin/phpunit --group functional
