# FreePBX with Asterisk in Docker image

[![Build Status](https://img.shields.io/docker/build/brainbeanapps/freepbx.svg)](https://hub.docker.com/r/brainbeanapps/freepbx)
[![Docker Pulls](https://img.shields.io/docker/pulls/brainbeanapps/freepbx.svg)](https://hub.docker.com/r/brainbeanapps/freepbx)
[![Docker Stars](https://img.shields.io/docker/stars/brainbeanapps/freepbx.svg)](https://hub.docker.com/r/brainbeanapps/freepbx)
[![Docker Layers](https://images.microbadger.com/badges/image/brainbeanapps/freepbx.svg)](https://microbadger.com/images/brainbeanapps/freepbx)

Dockerized version of [FreePBX](https://freepbx.org/) with [Asterisk](https://www.asterisk.org/) by [Brainbean Apps](https://brainbeanapps.com)

## Usage

```bash
docker run \
  --name freepbx \
  --restart unless-stopped \
  --net=host \
  -v /pbx/asterisk/etc:/etc/asterisk:rw \
  -v /pbx/asterisk/log:/var/log/asterisk:rw \
  -v /pbx/asterisk/lib:/var/lib/asterisk:rw \
  -v /pbx/asterisk/spool:/var/spool/asterisk:rw \
  -v /pbx/freepbx/freepbx.conf:/etc/freepbx.conf:rw \
  -v /pbx/freepbx/amportal.conf:/etc/amportal.conf:rw \
  -v /pbx/freepbx/odbc.ini:/etc/odbc.ini:rw \
  -v /pbx/db:/var/lib/mysql:rw \
  brainbeanapps/asterisk:latest
```

or

```bash
docker volume create pbx-asterisk-etc
docker volume create pbx-asterisk-log
docker volume create pbx-asterisk-lib
docker volume create pbx-asterisk-spool
docker volume create pbx-db
  --name freepbx \
  --restart unless-stopped \
  --net=host \
  -v pbx-asterisk-etc:/etc/asterisk:rw \
  -v pbx-asterisk-log:/var/log/asterisk:rw \
  -v pbx-asterisk-lib:/var/lib/asterisk:rw \
  -v pbx-asterisk-spool:/var/spool/asterisk:rw \
  -v /pbx/freepbx/freepbx.conf:/etc/freepbx.conf:rw \
  -v /pbx/freepbx/amportal.conf:/etc/amportal.conf:rw \
  -v /pbx/freepbx/odbc.ini:/etc/odbc.ini:rw \
  -v pbx-db:/var/lib/mysql:rw \
  brainbeanapps/asterisk:latest
```

## Network

Check default ports used [here](https://wiki.freepbx.org/display/PPS/Ports+used+on+your+PBX).
