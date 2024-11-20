#!/bin/bash

# shellcheck disable=SC1091
. /scripts/init.sh

run_valkey_command() {
    valkey-cli -h localhost -p "${SERVER_PORT}" "$@"
}

failover_finished() {
    VALKEY_ROLE=$(run_valkey_command role | head -1)
    [[ "$VALKEY_ROLE" != "master" ]]
}

if ! failover_finished; then
    echo "Waiting for sentinel to run failover for up to {{ sub .Values.sentinel.terminationGracePeriodSeconds 10 }}s"
    retry_while "failover_finished" 30 1
else
    exit 0
fi
