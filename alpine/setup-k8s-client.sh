#!/usr/bin/env ash
# shellcheck shell=dash
set -ex

# 安装 kubectl
wget https://dl.k8s.io/v1.25.0/kubernetes-client-linux-amd64.tar.gz -O - |
    tar -xzf - --strip-components=3 -C /usr/local/bin kubernetes/client/bin/kubectl kubernetes/client/bin/kubectl-convert
mkdir -p /usr/local/share/bash-completion/completions &&
    kubectl completion bash >/usr/local/share/bash-completion/completions/kubectl
