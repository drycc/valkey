ARG CODENAME
FROM registry.drycc.cc/drycc/base:${CODENAME}

ENV DRYCC_UID=1001 \
  DRYCC_GID=1001 \
  DRYCC_HOME_DIR=/data \
  VALKEY_VERSION="8.1.0" \
  VALKEY_SENTINEL_PROXY_VERSION="1.0.2"

RUN groupadd drycc --gid ${DRYCC_GID} \
  && useradd drycc -u ${DRYCC_UID} -g ${DRYCC_GID} -s /bin/bash -m -d ${DRYCC_HOME_DIR}

COPY scripts /scripts
COPY etc/valkey /etc/valkey
COPY bin/valkey-start /bin/valkey-start

RUN install-stack valkey ${VALKEY_VERSION} \
  && install-stack valkey-sentinel-proxy ${VALKEY_SENTINEL_PROXY_VERSION} \
  && rm -rf \
      /usr/share/doc \
      /usr/share/man \
      /usr/share/info \
      /usr/share/locale \
      /var/lib/apt/lists/* \
      /var/log/* \
      /var/cache/debconf/* \
      /etc/systemd \
      /lib/lsb \
      /lib/udev \
      /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/IBM* \
      /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/EBC* \
  && mkdir -p /usr/share/man/man{1..8} \
  && chown -R ${DRYCC_UID}:${DRYCC_GID} /etc/valkey ${DRYCC_HOME_DIR}

USER ${DRYCC_UID}
WORKDIR ${DRYCC_HOME_DIR}
EXPOSE 6379 26379
