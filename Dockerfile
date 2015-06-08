FROM alpine:latest

RUN apk --update add bash build-base znc znc-dev znc-extra \
     && rm -rf /var/cache/apk/*

COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 6667

ENTRYPOINT ["/docker-entrypoint.sh"]
