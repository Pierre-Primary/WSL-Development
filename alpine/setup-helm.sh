#!/bin/sh
set -ex

# 安装 helm
wget https://get.helm.sh/helm-v3.9.4-linux-amd64.tar.gz -O - |
    tar -xzf - --strip-components=1 -C /usr/local/bin linux-amd64/helm
mkdir -p /usr/local/share/bash-completion/completions &&
    helm completion bash >/usr/local/share/bash-completion/completions/helm
