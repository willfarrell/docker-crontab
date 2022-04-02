FROM golang:1.14-alpine as yj-build

WORKDIR /build
RUN apk add git \
    && git clone https://github.com/sclevine/yj.git && cd yj \
    && go build

FROM library/docker:stable

COPY --from=yj-build /build/yj/yj /usr/local/bin

ENV HOME_DIR=/opt/crontab
RUN apk add --no-cache --virtual .run-deps gettext jq bash tini \
    && mkdir -p ${HOME_DIR}/jobs ${HOME_DIR}/projects \
    && adduser -S docker -D

COPY docker-entrypoint /
ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint"]

HEALTHCHECK --interval=5s --timeout=3s \
    CMD ps aux | grep '[c]rond' || exit 1

CMD ["crond", "-f", "-d", "6", "-c", "/etc/crontabs"]
