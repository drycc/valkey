#!/bin/bash

# Constants
RESET='\033[0m'
RED='\033[38;5;1m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'

log() {
    # 'is_boolean_yes' is defined in libvalidations.sh, but depends on this file so we cannot source it
    local bool="${DRYCC_QUIET:-false}"
    # comparison is performed without regard to the case of alphabetic characters
    shopt -s nocasematch
    if ! [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
        printf "%b\\n" "${CYAN}${MODULE:-} ${MAGENTA}$(date "+%T.%2N ")${RESET}${*}" >&2
    fi
}

error() {
    log "${RED}ERROR${RESET} ==> ${*}"
    exit 1
}

########################
# Retries a command a given number of times
# Arguments:
#   $1 - cmd (as a string)
#   $2 - max retries. Default: 12
#   $3 - sleep between retries (in seconds). Default: 5
# Returns:
#   Boolean
#########################
retry_while() {
    local cmd="${1:?cmd is missing}"
    local retries="${2:-12}"
    local sleep_time="${3:-5}"
    local return_value=1

    read -r -a command <<<"$cmd"
    for ((i = 1; i <= retries; i += 1)); do
        "${command[@]}" && return_value=0 && break
        sleep "$sleep_time"
    done
    return $return_value
}

init_default_env() {
    if [[ -z "$DRYCC_VALKEY_SENTINEL" ]]; then
        error "DRYCC_VALKEY_SENTINEL cannot be empty"
    fi
    if [[ -z "$DRYCC_VALKEY_PASSWORD" ]]; then
        error "DRYCC_VALKEY_PASSWORD cannot be empty"
    fi
    mkdir -p /data/{server,sentinel}
    SERVER_PORT=${SERVER_PORT:-6379}
    SENTINEL_PORT=${SENTINEL_PORT:-26379}
    REDISCLI_AUTH="$DRYCC_VALKEY_PASSWORD"
    export SERVER_PORT SENTINEL_PORT REDISCLI_AUTH
}

init_default_env
