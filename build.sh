#!/bin/bash
set -e

function allowed_versions {
    versions=$(
        (echo 'value="5.2.0.==='; wget -qO- https://grafana.com/grafana/download | grep -o 'value="[^"]*"') | sort)
    after_line=$(echo "$versions" | grep -n "5.2.0.===" | cut -d ':' -f1)
    echo "$versions" | tail -n +$[after_line+1] | cut -d '"' -f2
}

if [ $# -lt 1 ]
then
    current_arch=$(uname -m)
    if [ "$current_arch" == "armv7l" ]
    then
        arch="armv7"
    # TODO Add support for arm64v8
    else
        echo "Unknown architecture"
        exit 1
    fi
else
    if [ "$1" == "-h" ]
    then
        echo 'Usage: build.sh [armv7|arm64] [Grafana version >= 5.2.0]'
        echo "  If no architecture is provided, it is autodetected from uname"
        echo "  If no Grafana version is provided, the latest stable release is used"
        echo "  If the provided Grafana version is \"nightly\", then the latest nightly build is used."
        exit 2
    else
        arch="$1"
        if [ $# -gt 1 ]
        then
            if [ "$2" == "nightly" ]
            then
                nightly_version=$(allowed_versions | tail -n1)
                grafana_download_url="https://grafana.com/grafana/download/${nightly_version}?platform=arm"
            else
                grafana_download_url="https://grafana.com/grafana/download/${2}?platform=arm"
            fi
        else
            grafana_download_url="https://grafana.com/grafana/download?platform=arm"
        fi
    fi
fi

# Get the URL for the latest tarball for armhf (ARMv7)
tarball=$(wget -qO- "$grafana_download_url" | sed -n "s/^.*href=\"\\([^\"]*.linux-${arch}.tar.gz\\)\".*$/\\1/p")

if [ "$tarball" == "" ]
then
    echo "Tarball not found matching provided architecture"
    exit 3
fi

# Get the version identified in the tarball:
version=$(basename "$tarball" | sed "s/grafana-\\(.*\\)\\.linux-${arch}.tar.gz/\\1/")

# Pull down the Dockerfile and entrypoint script from the GitHub repo, either from the tagged version (if it exists), or the master branch otherwise.
if wget -O Dockerfile "https://raw.githubusercontent.com/grafana/grafana/v${version}/packaging/docker/Dockerfile"
then
    wget -O run.sh "https://raw.githubusercontent.com/grafana/grafana/v${version}/packaging/docker/run.sh"
else
    wget -O Dockerfile "https://raw.githubusercontent.com/grafana/grafana/master/packaging/docker/Dockerfile"
    wget -O run.sh "https://raw.githubusercontent.com/grafana/grafana/master/packaging/docker/run.sh"
fi

chmod +x run.sh

# Pull down the tarball
wget --no-clobber "$tarball"

docker build --build-arg GRAFANA_TGZ=`basename "$tarball"` -t grafana:${version}-${arch} .

# Some housekeeping cleanup
rm `basename "$tarball"` Dockerfile run.sh
