#!/usr/bin/env bash
set -ex

dir=$(
    cd "$(dirname "$0")"
    pwd
)

"$dir/setup-openrc.sh"

apk add mariadb
rc-update add mariadb default
service mariadb start
