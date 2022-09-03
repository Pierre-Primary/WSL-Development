#!/bin/sh
set -ex

# 依赖 setup-openrc.sh

# 安装服务
apk add mariadb

# 初始化
/etc/init.d/mariadb setup

# 启动
rc-update add mariadb default
rc-service mariadb start

# 安装客户端
apk add mariadb-client
