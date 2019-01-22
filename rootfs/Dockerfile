FROM redis:5-alpine

COPY . /

RUN chown -R redis:redis /etc/redis

USER redis

CMD ["/bin/boot"]
EXPOSE 6379
