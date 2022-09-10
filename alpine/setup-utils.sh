#!/usr/bin/env ash
# shellcheck shell=dash
set -ex

# 和 busybox 相似，基础命令集（echo,ls,cp,mv,rm,mkdir,touch,ln,cat,seq,su,who,dd,du,df 等等）
apk add coreutils

# busybox 拓展命令集 (telnet 等等)
apk add busybox-extras

apk add util-linux

apk add shadow

apk add sudo

# 证书管理
apk add ca-certificates

# http协议请求和下载工具
apk add curl wget

# 其他网络调试工具
apk add nmap socat

# 网络管理 ip a
apk add iproute2

# 网络管理 ifconfig
apk add net-tools

# 网桥管理 brctl
apk add bridge-utils

# ps top free 等命令
apk add procps

# 完整版的命令； 区别于 busybox 和 coreutils
apk add grep sed gawk less

# 压缩解压工具
apk add tar gzip xz bzip2

# 打印文件目录树
apk add tree

# 带高亮的 cat
apk add bat

# json 和 yaml 脚本解析工具
apk add jq yq

# 文件编辑器 nano
apk add nano nano-syntax

# 文件编辑器 vim
apk add vim

# 文件编辑器 neovim； 和 vim 相似
apk add neovim

# 安装 ssh客户端
apk add openssh-client
# apk add openssh
# rc-update add sshd
# service sshd start

apk add git subversion

# apk add musl-locales
# sed -ie "/^export LANG=/d" /etc/profile.d/locale.sh
# echo "export LANG=zh_CN.UTF-8" >>/etc/profile.d/locale.sh
