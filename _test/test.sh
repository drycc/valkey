#!/usr/bin/env bash

VERSION="$1"

CONTAINER_NETWORK="valkey"
CONTAINER_MASTER_NAME="valkey-benchmark-master"
CONTAINER_SLAVE1_NAME="valkey-benchmark-slave1"
CONTAINER_SLAVE2_NAME="valkey-benchmark-slave2"
DRYCC_VALKEY_SENTINEL=$CONTAINER_MASTER_NAME
DRYCC_VALKEY_PASSWORD=123456

function clean_before_exit {
    # delay before exiting, so stdout/stderr flushes through the logging system
    clean-valkey
}
trap clean_before_exit EXIT

start-valkey-master() {
    podman run -d \
      --rm \
      --network "$CONTAINER_NETWORK" \
      --ip 192.168.253.10 \
      --add-host="$CONTAINER_MASTER_NAME:192.168.253.10" \
      --add-host="$CONTAINER_SLAVE1_NAME:192.168.253.11" \
      --add-host="$CONTAINER_SLAVE2_NAME:192.168.253.12" \
      --env "REDISCLI_AUTH=$DRYCC_VALKEY_PASSWORD" \
      --env "DRYCC_VALKEY_SENTINEL=$DRYCC_VALKEY_SENTINEL" \
      --env "DRYCC_VALKEY_PASSWORD=$DRYCC_VALKEY_PASSWORD" \
      --name "$CONTAINER_MASTER_NAME" \
      "registry.drycc.cc/drycc/valkey:$VERSION" \
      valkey-start server $CONTAINER_MASTER_NAME
    podman exec "$CONTAINER_MASTER_NAME" init-stack valkey-start sentinel $CONTAINER_MASTER_NAME &
}

start-valkey-slave1() {
    podman run -d \
      --rm \
      --network "$CONTAINER_NETWORK" \
      --ip 192.168.253.11 \
      --add-host="$CONTAINER_MASTER_NAME:192.168.253.10" \
      --add-host="$CONTAINER_SLAVE1_NAME:192.168.253.11" \
      --add-host="$CONTAINER_SLAVE2_NAME:192.168.253.12" \
      --env "REDISCLI_AUTH=$DRYCC_VALKEY_PASSWORD" \
      --env "DRYCC_VALKEY_SENTINEL=$DRYCC_VALKEY_SENTINEL" \
      --env "DRYCC_VALKEY_PASSWORD=$DRYCC_VALKEY_PASSWORD" \
      --name "$CONTAINER_SLAVE1_NAME" \
      "registry.drycc.cc/drycc/valkey:$VERSION" \
      valkey-start server $CONTAINER_SLAVE1_NAME
    podman exec "$CONTAINER_SLAVE1_NAME" init-stack valkey-start sentinel $CONTAINER_SLAVE1_NAME &
}

start-valkey-slave2() {
    podman run -d \
      --rm \
      --network "$CONTAINER_NETWORK" \
      --ip 192.168.253.12 \
      --add-host="$CONTAINER_MASTER_NAME:192.168.253.10" \
      --add-host="$CONTAINER_SLAVE1_NAME:192.168.253.11" \
      --add-host="$CONTAINER_SLAVE2_NAME:192.168.253.12" \
      --env "REDISCLI_AUTH=$DRYCC_VALKEY_PASSWORD" \
      --env "DRYCC_VALKEY_SENTINEL=$DRYCC_VALKEY_SENTINEL" \
      --env "DRYCC_VALKEY_PASSWORD=$DRYCC_VALKEY_PASSWORD" \
      --name "$CONTAINER_SLAVE2_NAME" \
      "registry.drycc.cc/drycc/valkey:$VERSION" \
      valkey-start server $CONTAINER_SLAVE2_NAME
    podman exec "$CONTAINER_SLAVE2_NAME" init-stack valkey-start sentinel $CONTAINER_SLAVE2_NAME &
}

clean-valkey() {
    {
        podman stop -i "$CONTAINER_SLAVE1_NAME"
        podman stop -i "$CONTAINER_SLAVE2_NAME"
        podman stop -i "$CONTAINER_MASTER_NAME"
        podman network rm -f "$CONTAINER_NETWORK"
    } 2>>/dev/null
}

clean-valkey
podman network create --subnet=192.168.253.0/24 "$CONTAINER_NETWORK"
start-valkey-master
start-valkey-slave1
start-valkey-slave2

echo "run valkey benchmark..."
podman exec "$CONTAINER_MASTER_NAME" init-stack valkey-benchmark -a $DRYCC_VALKEY_PASSWORD

echo "check slave all keys..."
KEYS=$(podman exec "$CONTAINER_MASTER_NAME" bash -c 'init-stack valkey-cli KEYS "*"')
if [[ "${KEYS}" == "" ]]; then
    echo "error: there is no data from the database"
    exit 1
fi

echo "check sentinel $CONTAINER_MASTER_NAME get master..."
MASTER=$(podman exec "$CONTAINER_MASTER_NAME" init-stack valkey-cli -p 26379 sentinel get-master-addr-by-name drycc)
if [[ "${MASTER}" == "" ]]; then
    echo "error: unable to obtain master information"
    exit 1
fi

echo "check sentinel $CONTAINER_SLAVE1_NAME get master..."
MASTER=$(podman exec "$CONTAINER_SLAVE1_NAME" init-stack valkey-cli -p 26379 sentinel get-master-addr-by-name drycc)
if [[ "${MASTER}" == "" ]]; then
    echo "error: unable to obtain master information"
    exit 1
fi

echo "check sentinel $CONTAINER_SLAVE2_NAME get master..."
MASTER=$(podman exec "$CONTAINER_SLAVE2_NAME" init-stack valkey-cli -p 26379 sentinel get-master-addr-by-name drycc)
if [[ "${MASTER}" == "" ]]; then
    echo "error: unable to obtain master information"
    exit 1
fi

echo "check sentinel $CONTAINER_MASTER_NAME get slaves..."
SLAVES=$(podman exec "$CONTAINER_MASTER_NAME" init-stack valkey-cli -p 26379 sentinel replicas drycc)
if [[ "${SLAVES}" == "" ]]; then
    echo "error: unable to obtain slaves information"
    exit 1
fi

echo "check sentinel $CONTAINER_SLAVE1_NAME get slaves..."
SLAVES=$(podman exec "$CONTAINER_SLAVE1_NAME" init-stack valkey-cli -p 26379 sentinel replicas drycc)
if [[ "${SLAVES}" == "" ]]; then
    echo "error: unable to obtain slaves information"
    exit 1
fi

echo "check sentinel $CONTAINER_SLAVE2_NAME get slaves..."
SLAVES=$(podman exec "$CONTAINER_SLAVE2_NAME" init-stack valkey-cli -p 26379 sentinel replicas drycc)
if [[ "${SLAVES}" == "" ]]; then
    echo "error: unable to obtain slaves information"
    exit 1
fi

echo "all test ok..."
