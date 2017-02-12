# docker-crontab

A simple wrapper over `docker` to all complex cron job to be run in other containers. All in <45MB.

## Supported tags and Dockerfile links

-	[`latest` (*Dockerfile*)](https://github.com/willfarrell/docker-crontab/blob/master/Dockerfile)

[![](https://images.microbadger.com/badges/version/willfarrell/crontab.svg)](http://microbadger.com/images/willfarrell/crontab "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/willfarrell/crontab.svg)](http://microbadger.com/images/willfarrell/crontab "Get your own image badge on microbadger.com")


## Why?
Yes, I'm aware of [mcuadros/ofelia](https://github.com/mcuadros/ofelia) (280MB), it was the main inspiration for this project. 
A great project, don't get me wrong. It was just missing certain key enterprise features I felt were required to support where docker is heading.

## Features
- Easy to read schedule syntax allowed.
- Allows for comments, cause we all need friendly reminders of what `update_script.sh` actually does.
- Start an image using `image`.
- Run command in a container using `container`.
- Run command on a instances of a scaled container using `project`.
- Ability to trigger scripts in other containers on completion cron job using `trigger`.

## Config.json
- `comment`: Comments to be included with crontab entry
- `schedule`: Crontab schedule syntax as described in https://godoc.org/github.com/robfig/cron. Ex `@hourly`, `@every 1h30m`, `* * * * * *`. Required.
- `command`: Command to be run on docker container/image. Required.
- `image`: Docker images name (ex `library/alpine:3.5`). Optional.
- `project`: Docker Compose/Swarm project name. Optional, only applies when `contain` is included.
- `container`: Full container name or container alias if `project` is set. Ignored if `image` is included.
- `dockerargs`: Command line docker `run`/`exec` arguments for full control. Defaults to ` `.
- `trigger`: Array of docker-crontab subset objects. Subset includes: `image`,`project`,`container`,`command`,`dockerargs` 

See `./config.sample.json` for examples.

## Examples

### Command Line
```bash
docer build -t crontab .
docker run -d \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /usr/bin/docker:/usr/bin/docker \
    -v /path/to/config/dir:/opt/crontab \
    crontab
```

### Dockerfile
```Dockerfile
FROM willfarrell/crontab

COPY config.json ${HOME_DIR}/
```

### Logrotate Dockerfile
```Dockerfile
FROM willfarrell/crontab

RUN apk add --no-cache logrotate
RUN echo "*/5 *	* * *  /usr/sbin/logrotate /etc/logrotate.conf" >> /etc/crontabs/logrotate
ADD logrotate.conf /etc/logrotate.conf

CMD ["crond", "-f"]
```

## TODO
- [ ] Make smaller by using busybox?
- [ ] Have ability to auto regenerate crontab on file change
- [ ] Run commands on host machine
- [ ] Write tests
- [ ] Setup TravisCI