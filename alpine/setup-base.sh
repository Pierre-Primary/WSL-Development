#!/usr/bin/env bash
set -ex

# 换源
sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
apk update

# apk add ca-certificates util-linux
apk add busybox-extras
apk add coreutils

apk add curl wget

apk add grep sed gawk less
apk add tar gzip xz bzip2
apk add procps
apk add iproute2
# apk add net-tools
# apk add tree

apk add nano nano-syntax
apk add jq yq
# apk add neovim bat
apk add nmap socat

# 安装 ssh客户端
apk add openssh-client
# apk add openssh
# rc-update add sshd
# service sshd start

apk add git subversion

# 安装 sudo
apk add sudo
echo '%wheel ALL=(ALL) ALL' >/etc/sudoers.d/wheel

# apk add musl-locales
# sed -ie "/^export LANG=/d" /etc/profile.d/locale.sh
# echo "export LANG=zh_CN.UTF-8" >>/etc/profile.d/locale.sh
