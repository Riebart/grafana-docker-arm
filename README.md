# Grafana Docker Images for ARM

Build script to build a Docker container for Grafana from the official Dockerfile for ARM architectures.

This build script only recognized ARM architectures, since x86_64 already exists. It runs just fine on Raspbian (arm32v7), and will auto-detect sensible defaults (architecture from `uname -m`, and version from the latest stable release version), so building the container is as simple as:

```bash
$ bash build.sh
grafana:5.2.2-armv7
```

Note that the script emits that built container name:tag on stdout if a container is built, and if the container it _would have built_ already exists, it just emits an empty line.

## Running it daily

This isn't strictly necessary, as I run it hourly (or, will until Grafana produces official ARM docker containers) and push the results to [DockerHub](https://hub.docker.com/r/riebart/grafana-arm), but there's no reason you should trust my images, so I've simplified running it via cron. My crontab line is:

```crontab
0 * * * * bash /home/pi/Documents/grafana-docker-arm/cronjob.sh riebart/grafana-arm
```

This will attempt to build the latest stable (giving up if there's no new stable to build), and the latest nightly (which release about hourly, give or take) builds. If new versions of either exist, it'll tag them as `latest-<arch>` and `nightly-arch` respectively, and push them to the repository specified. Note that the repository can be a private one, that's totally fine.
