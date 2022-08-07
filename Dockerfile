FROM alpine:latest as rq-build

ENV RQ_VERSION=1.0.2
WORKDIR /usr/bin/rq/

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        upx && \
    wget https://github.com/dflemstr/rq/releases/download/v${RQ_VERSION}/rq-v${RQ_VERSION}-x86_64-unknown-linux-musl.tar.gz && \
    tar -xvf rq-v${RQ_VERSION}-x86_64-unknown-linux-musl.tar.gz && \
    upx --brute rq

FROM docker:latest as release

ENV HOME_DIR=/opt/crontab

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        bash \
        curl \
        gettext \
        jq \
        tini \
        wget && \
    mkdir -p ${HOME_DIR}/jobs ${HOME_DIR}/projects && \
    adduser -S docker -D

COPY --from=rq-build /usr/bin/rq/rq /usr/local/bin
COPY entrypoint.sh /

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]

HEALTHCHECK --interval=5s --timeout=3s \
    CMD ps aux | grep '[c]rond' || exit 1

CMD ["crond", "-f", "-d", "6", "-c", "/etc/crontabs"]
