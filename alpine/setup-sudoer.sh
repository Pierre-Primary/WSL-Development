#!/usr/bin/env sh
set -ex

# 安装 sudo
apk add sudo
echo '%wheel ALL=(ALL) ALL' | tee /etc/sudoers.d/wheel >/dev/null
