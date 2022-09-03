#!/usr/bin/env bash
set -ex

# 依赖 setup-openrc.sh

apk add mariadb
rc-update add mariadb default
service mariadb start
