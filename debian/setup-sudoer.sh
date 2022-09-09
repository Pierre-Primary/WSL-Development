#!/usr/bin/env sh
set -ex

# 安装 sudo
apt install -y sudo
echo '%sudo ALL=(ALL) ALL' | tee /etc/sudoers.d/sudo >/dev/null
