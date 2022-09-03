#!/bin/sh
set -ex

# 安装 sudo
apk add sudo
echo '%wheel ALL=(ALL) ALL' >/etc/sudoers.d/wheel
