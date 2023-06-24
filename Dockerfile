#hadolint ignore=DL3007
FROM alpine:latest as builder

LABEL org.opencontainers.image.title="crontab builder" \
      org.opencontainers.image.description="crontab builder" \
      org.opencontainers.image.authors="robert@simplicityguy.com" \
      org.opencontainers.image.source="https://github.com/SimplicityGuy/alertmanager-discord/blob/main/Dockerfile" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.created="$(date +'%Y-%m-%d')" \
      org.opencontainers.image.base.name="docker.io/library/alpine"

ENV RQ_VERSION=1.0.2
WORKDIR /usr/bin/rq/

#hadolint ignore=DL3018
RUN apk update --quiet --no-cache && \
    apk upgrade --quiet --no-cache && \
    apk add --quiet --no-cache \
        upx && \
    rm /var/cache/apk/* && \
    wget --quiet https://github.com/dflemstr/rq/releases/download/v${RQ_VERSION}/rq-v${RQ_VERSION}-x86_64-unknown-linux-musl.tar.gz && \
    tar -xvf rq-v${RQ_VERSION}-x86_64-unknown-linux-musl.tar.gz && \
    upx --brute rq

#hadolint ignore=DL3007
FROM docker:latest as release

LABEL org.opencontainers.image.title="crontab" \
      org.opencontainers.image.description="A docker job scheduler (aka crontab for docker)." \
      org.opencontainers.image.authors="robert@simplicityguy.com" \
      org.opencontainers.image.source="https://github.com/SimplicityGuy/docker-crontab/blob/main/Dockerfile" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.created="$(date +'%Y-%m-%d')" \
      org.opencontainers.image.base.name="docker.io/library/docker"

ENV HOME_DIR=/opt/crontab

#hadolint ignore=DL3018
RUN apk update --quiet --no-cache && \
    apk upgrade --quiet --no-cache && \
    apk add --quiet --no-cache \
        bash \
        coreutils \
        curl \
        gettext \
        jq \
        tini \
        wget && \
    rm /var/cache/apk/* && \
    mkdir -p ${HOME_DIR}/jobs && \
    rm -rf /etc/periodic /etc/crontabs/root && \
    adduser -S docker -D

COPY --from=builder /usr/bin/rq/rq /usr/local/bin
COPY entrypoint.sh /

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]

HEALTHCHECK --interval=5s --timeout=3s \
    CMD ps aux | grep '[c]rond' || exit 1

CMD ["crond", "-f", "-d", "6", "-c", "/etc/crontabs"]
