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

# 安装 docker
./setup-docker.sh

apk add curl

curl -sfL https://rancher-mirror.oss-cn-beijing.aliyuncs.com/k3s/k3s-install.sh |
    INSTALL_K3S_MIRROR=cn \
        sh -s -- server \
        --docker \
        --write-kubeconfig-mode 644
