#!/usr/bin/env ash
# shellcheck shell=bash
set -ex

# 安装并启动 openrc
if [ "$1" != "--enter" ]; then
    ./setup-openrc.sh
    /etc/wsl-init/enter "$0 --enter"
    exit
fi

cd "$(dirname "$0")"

# 安装服务
install_service() {

    type /usr/bin/dockerd >/dev/null && return

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
    rc-service docker start
}

# 安装客户端
install_cli() {
    apk add docker-cli docker-cli-compose docker-cli-buildx
}

install_service
install_cli
