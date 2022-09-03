#!/bin/sh
set -ex

cd "$(dirname "$0")"

# 安装 openrc
./setup-openrc.sh

# 安装服务
apk add docker

# 备份配置
mv /etc/conf.d/docker /etc/conf.d/docker.default
# 修改配置
cat <<EOF | tee /etc/conf.d/docker
#DOCKER_LOGFILE="/var/log/docker.log"
#DOCKER_OUTFILE="/var/log/docker-out.log"
#DOCKER_ERRFILE="/var/log/docker-err.log"
#DOCKER_ULIMIT="-c unlimited -n 1048576 -u unlimited"
#DOCKER_RETRY="TERM/60/KILL/10"
DOCKERD_BINARY="/usr/bin/dockerd"
DOCKER_OPTS="-H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375"
EOF

# 启动
rc-update add docker default
service docker start

# 安装客户端
apk add docker-cli docker-cli-compose docker-cli-buildx
