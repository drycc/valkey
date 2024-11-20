#!/bin/bash

# shellcheck disable=SC1091
. /scripts/init.sh

response=$(
    timeout -s 3 "$1" \
    valkey-cli \
    -h localhost \
    -p "${SERVER_PORT}" \
    ping
)
if [ "$?" -eq "124" ]; then
    echo "Timed out"
    exit 1
fi
if [ "$response" != "PONG" ]; then
    echo "$response"
    exit 1
fi