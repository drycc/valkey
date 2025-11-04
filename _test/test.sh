#!/usr/bin/env bash

VERSION="$1"

CONTAINER_PROXY_NAME="valkey-benchmark-proxy"
CONTAINER_MASTER_NAME="valkey-benchmark-master"
CONTAINER_SLAVE1_NAME="valkey-benchmark-slave1"
CONTAINER_SLAVE2_NAME="valkey-benchmark-slave2"
DRYCC_VALKEY_PASSWORD=123456

function clean_before_exit {
    # delay before exiting, so stdout/stderr flushes through the logging system
    clean-valkey
}
trap clean_before_exit EXIT

start-valkey-master() {
    podman run -d \
      --rm \
      --env "REDISCLI_AUTH=$DRYCC_VALKEY_PASSWORD" \
      --env "DRYCC_VALKEY_PASSWORD=$DRYCC_VALKEY_PASSWORD" \
      --name "$CONTAINER_MASTER_NAME" \
      "registry.drycc.cc/drycc/valkey:$VERSION" \
      sleep infinity

    master_ip=$(podman exec "$CONTAINER_MASTER_NAME" hostname -i | tr -d '\r\n')
    podman exec --env "DRYCC_VALKEY_SENTINEL=$master_ip" "$CONTAINER_MASTER_NAME" init-stack valkey-start server "$master_ip"  &
    podman exec --env "DRYCC_VALKEY_SENTINEL=$master_ip" "$CONTAINER_MASTER_NAME" init-stack valkey-start sentinel "$master_ip" &
}

start-valkey-slave1() {
    podman run -d \
      --rm \
      --env "REDISCLI_AUTH=$DRYCC_VALKEY_PASSWORD" \
      --env "DRYCC_VALKEY_PASSWORD=$DRYCC_VALKEY_PASSWORD" \
      --name "$CONTAINER_SLAVE1_NAME" \
      "registry.drycc.cc/drycc/valkey:$VERSION" \
      sleep infinity

    slave1_ip=$(podman exec -it "$CONTAINER_SLAVE1_NAME" hostname -i | tr -d '\r\n')
    podman exec --env "DRYCC_VALKEY_SENTINEL=$master_ip" "$CONTAINER_SLAVE1_NAME" init-stack valkey-start server "$slave1_ip" &
    podman exec --env "DRYCC_VALKEY_SENTINEL=$master_ip" "$CONTAINER_SLAVE1_NAME" init-stack valkey-start sentinel "$slave1_ip" &
}

start-valkey-slave2() {
    podman run -d \
      --rm \
      --env "REDISCLI_AUTH=$DRYCC_VALKEY_PASSWORD" \
      --env "DRYCC_VALKEY_PASSWORD=$DRYCC_VALKEY_PASSWORD" \
      --name "$CONTAINER_SLAVE2_NAME" \
      "registry.drycc.cc/drycc/valkey:$VERSION" \
      sleep infinity

    slave2_ip=$(podman exec -it "$CONTAINER_SLAVE2_NAME" hostname -i | tr -d '\r\n')
    podman exec --env "DRYCC_VALKEY_SENTINEL=$master_ip" "$CONTAINER_SLAVE2_NAME" init-stack valkey-start server "$slave2_ip" &
    podman exec --env "DRYCC_VALKEY_SENTINEL=$master_ip" "$CONTAINER_SLAVE2_NAME" init-stack valkey-start sentinel "$slave2_ip" &
}

start-valkey-proxy() {
    podman run -d \
      --rm \
      --env "REDISCLI_AUTH=$DRYCC_VALKEY_PASSWORD" \
      --env "DRYCC_VALKEY_PASSWORD=$DRYCC_VALKEY_PASSWORD" \
      --name "$CONTAINER_PROXY_NAME" \
      "registry.drycc.cc/drycc/valkey:$VERSION" \
      sleep infinity

    podman exec --env "DRYCC_VALKEY_SENTINEL=$master_ip" "$CONTAINER_PROXY_NAME" init-stack valkey-start proxy &
}

clean-valkey() {
    {
        podman kill "$CONTAINER_PROXY_NAME"
        podman kill "$CONTAINER_SLAVE1_NAME"
        podman kill "$CONTAINER_SLAVE2_NAME"
        podman kill "$CONTAINER_MASTER_NAME"
    } >>/dev/null 2>&1
}

clean-valkey
start-valkey-master
start-valkey-slave1
start-valkey-slave2
start-valkey-proxy
echo "run valkey proxy benchmark..."
podman exec "$CONTAINER_PROXY_NAME" init-stack valkey-benchmark -p 16379 -a $DRYCC_VALKEY_PASSWORD

echo "run valkey master benchmark..."
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
