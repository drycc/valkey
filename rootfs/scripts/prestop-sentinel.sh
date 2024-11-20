#!/bin/bash

# shellcheck disable=SC1091
. /scripts/init.sh

run_sentinel_command() {
    valkey-cli -h "$DRYCC_VALKEY_SENTINEL" -p "${SENTINEL_PORT}" sentinel "$@"
}

failover_finished() {
    # shellcheck disable=SC2207
    SENTINEL_INFO=($(run_sentinel_command get-master-addr-by-name drycc))
    VALKEY_MASTER_HOST="${SENTINEL_INFO[0]}"
    [[ "$VALKEY_MASTER_HOST" != "$(hostname -I | xargs)" ]]
}

if ! failover_finished; then
    echo "I am the master pod and you are stopping me. Starting sentinel failover"
    # if I am the master, issue a command to failover once and then wait for the failover to finish
    run_sentinel_command failover drycc
    if retry_while "failover_finished" 30 1; then
        echo "Master has been successfuly failed over to a different pod."
        exit 0
    else
        echo "Master failover failed"
        exit 1
    fi
else
    exit 0
fi