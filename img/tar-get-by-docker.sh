#!/usr/bin/env sh
set -ex

cd "$(dirname "$0")"

VERSION=${1:-"latest"}

TAR_FILE=$(pwd)/output/alpine-$VERSION-docker.tar
IMAGE_NAME=alpine:$VERSION
if [ -e "$TAR_FILE" ]; then
    echo "$TAR_FILE"
    exit
fi
{

    mkdir -p "$(dirname "$TAR_FILE")"

    NAME=$(mktemp -u XXXXXXXXXX)

    docker run -d --name="$NAME" "$IMAGE_NAME"

    docker stop "$NAME"

    rm -f "$TAR_FILE"

    docker export "$NAME" -o "$TAR_FILE"

    docker rm "$NAME"
} >/dev/null

echo "$TAR_FILE"
