# crontab

![crontab](https://github.com/SimplicityGuy/adocker-crontab/actions/workflows/build.yml/badge.svg) ![License: MIT](https://img.shields.io/github/license/SimplicityGuy/docker-crontab) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)

A simple wrapper over `docker` to all complex cron job to be run in other containers.

## Why?

Yes, I'm aware of [mcuadros/ofelia](https://github.com/mcuadros/ofelia) (>250MB when this was created), it was the main inspiration for this project.
A great project, don't get me wrong. It was just missing certain key enterprise features I felt were required to support where docker is heading.

## Features

- Easy to read schedule syntax allowed.
- Allows for comments, cause we all need friendly reminders of what `update_script.sh` actually does.
- Start an image using `image`.
- Run command in a container using `container`.
- Ability to trigger scripts in other containers on completion cron job using `trigger`.
- Ability to share settings between cron jobs using `~~shared-settings` as a key.

## Config file

The config file can be specified in any of `json`, `toml`, or `yaml`, and can be defined as either an array or mapping (top-level keys will be ignored; can be useful for organizing commands)

- `name`: Human readable name that will be used as the job filename. Will be converted into a slug. Optional.
- `comment`: Comments to be included with crontab entry. Optional.
- `schedule`: Crontab schedule syntax as described in https://en.wikipedia.org/wiki/Cron. Examples: `@hourly`, `@every 1h30m`, `* * * * *`. Required.
- `command`: Command to be run on in crontab container or docker container/image. Required.
- `image`: Docker images name (ex `library/alpine:3.5`). Optional.
- `container`: Full container name. Ignored if `image` is included. Optional.
- `dockerargs`: Command line docker `run`/`exec` arguments for full control. Defaults to ` `.
- `trigger`: Array of docker-crontab subset objects. Sub-set includes: `image`, `container`, `command`, `dockerargs`
- `onstart`: Run the command on `crontab` container start, set to `true`. Optional, defaults to false.

See [`config-samples`](config-samples) for examples.

```json
{
    "logrotate": {
        "schedule":"@every 5m",
        "command":"/usr/sbin/logrotate /etc/logrotate.conf"
    },
    "cert-regen": {
        "comment":"Regenerate Certificate then reload nginx",
        "schedule":"43 6,18 * * *",
        "command":"sh -c 'dehydrated --cron --out /etc/ssl --domain ${LE_DOMAIN} --challenge dns-01 --hook dehydrated-dns'",
        "dockerargs":"--it --env-file /opt/crontab/env/letsencrypt.env",
        "volumes":["webapp_nginx_tls_cert:/etc/ssl", "webapp_nginx_acme_challenge:/var/www/.well-known/acme-challenge"],
        "image":"willfarrell/letsencrypt",
        "trigger":[{
            "command":"sh -c '/etc/scripts/make_hpkp ${NGINX_DOMAIN} && /usr/sbin/nginx -t && /usr/sbin/nginx -s reload'",
            "container":"nginx"
        }],
        "onstart":true
    }
}
```

## How to use

### Command Line

```bash
docker build -t crontab .
docker run -d \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v ./env:/opt/env:ro \
    -v /path/to/config/dir:/opt/crontab:rw \
    -v /path/to/logs:/var/log/crontab:rw \
    crontab
```

### Use with docker-compose

1. Figure out which network name used for your docker-compose containers
   - use `docker network ls` to see existing networks
   - if your `docker-compose.yml` is in `my_dir` directory, you probably has network `my_dir_default`
   - otherwise [read the docker-compose docs](https://docs.docker.com/compose/networking/)
1. Add `dockerargs` to your docker-crontab `config.json`
   - use `--network NETWORK_NAME` to connect new container into docker-compose network
   - use `--name NAME` to use named container
   - e.g. `"dockerargs": "--it"`

### Dockerfile

```Dockerfile
FROM registry.gitlab.com/simplicityguy/docker/crontab

COPY config.json ${HOME_DIR}/
```

### Logrotate Dockerfile

```Dockerfile
FROM registry.gitlab.com/simplicityguy/docker/crontab

RUN apk add --no-cache logrotate
RUN echo "*/5 *	* * *  /usr/sbin/logrotate /etc/logrotate.conf" >> /etc/crontabs/logrotate
COPY logrotate.conf /etc/logrotate.conf

CMD ["crond", "-f"]
```
