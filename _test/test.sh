#!/usr/bin/env bash

VERSION="$1"
CONTAINER_NAME="valkey-benchmark"

function clean_before_exit {
    # delay before exiting, so stdout/stderr flushes through the logging system
    clean-valkey
}
trap clean_before_exit EXIT

start-valkey() {
    podman run -d --name "$CONTAINER_NAME" --rm registry.drycc.cc/drycc/valkey:$VERSION
}

clean-valkey() {
    podman rm -f "$CONTAINER_NAME"
}

clean-valkey
start-valkey
podman exec "$CONTAINER_NAME" /opt/drycc/valkey/bin/valkey-benchmark
