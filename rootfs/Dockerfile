FROM docker.io/drycc/base:bullseye

RUN adduser --system \
   --shell /bin/bash \
   --disabled-password \
   --home /data \
   --group \
   redis

COPY bin/boot /bin/boot
COPY etc/redis/redis.conf /etc/redis/redis.conf
ENV REDIS_VERSION="6.2.6"

RUN install-stack redis $REDIS_VERSION \
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
  && bash -c "mkdir -p /usr/share/man/man{1..8}" \
  && chown -R redis:redis /etc/redis /data

USER redis
CMD ["/bin/boot"]
EXPOSE 6379
