FROM docker.io/drycc/base:bullseye

ENV DRYCC_UID=1001 \
  DRYCC_GID=1001 \
  DRYCC_HOME_DIR=/data \
  REDIS_VERSION="6.2.6"

RUN groupadd drycc --gid ${DRYCC_GID} \
  && useradd drycc -u ${DRYCC_UID} -g ${DRYCC_GID} -s /bin/bash -m -d ${DRYCC_HOME_DIR}

COPY bin/boot /bin/boot
COPY etc/redis/redis.conf /etc/redis/redis.conf

RUN install-stack redis ${REDIS_VERSION} \
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
  && chown -R ${DRYCC_UID}:${DRYCC_GID} /etc/redis ${DRYCC_HOME_DIR}

USER ${DRYCC_UID}
WORKDIR ${DRYCC_HOME_DIR}
CMD ["/bin/boot"]
EXPOSE 6379
