#!/usr/bin/env bash
set -ex

apk add mariadb
rc-update add mariadb default
service mariadb start
