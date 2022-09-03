#!/bin/sh
set -ex

cd "$(dirname "$0")"

# 安装 docker
./setup-docker.sh

curl -sfL https://rancher-mirror.oss-cn-beijing.aliyuncs.com/k3s/k3s-install.sh |
    INSTALL_K3S_MIRROR=cn \
        sh -s -- server \
        --docker \
        --write-kubeconfig-mode 644
