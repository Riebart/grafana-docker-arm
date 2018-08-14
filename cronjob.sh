#!/bin/bash

# Script to run daily to build any new images, and push to a remote repository

if [ "$1" == "" ]
then
    echo "Usage: cronjob.sh <repository name>"
    exit 1
fi

function image_tag {
    echo "$1" | cut -d ':' -f2-
}

function image_arch {
    # Ref: https://stackoverflow.com/questions/3162385/how-to-split-a-string-in-shell-and-get-the-last-field
    echo ${1##*-}
}

# Build the latest stable release
stable_image=`bash build.sh`

if [ "$stable_image" != "" ]
then
    tag=`image_tag "$stable_image"`
    arch=`image_arch "$stable_image"`
    docker tag "$stable_image" "$1:$tag"
    docker push "$1:$tag"
    docker tag "$stable_image" "$1:latest-$arch"
    docker push "$1:latest-$arch"
fi

# Build the latest nightly release
nightly_image=`bash build.sh "" "nightly"`

if [ "$nightly_image" != "" ]
then
    tag=`image_tag "$nightly_image"`
    docker tag "$nightly_image" "$1:$tag"
    docker push "$1:$tag"
fi
