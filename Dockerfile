FROM library/alpine:3.5

ENV HOME_DIR=/opt/crontab
RUN apk add --no-cache --virtual .run-deps bash curl jq docker \
    && mkdir -p ${HOME_DIR}

# Dev
#COPY config.json ${HOME_DIR}/

COPY docker-entrypoint /
ENTRYPOINT ["/docker-entrypoint"]

HEALTHCHECK --interval=5s --timeout=3s \
    CMD ps aux | grep '[c]rond' || exit 1

CMD ["crond","-f"]