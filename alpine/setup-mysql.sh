#!/bin/sh
set -ex

apk add mariadb mariadb-client

/etc/init.d/mariadb setup

rc-update add mariadb default
rc-service mariadb start
