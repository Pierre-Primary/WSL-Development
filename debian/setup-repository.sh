#!/bin/sh
set -ex

# 换源
sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
sed -ir '/^\s*#/d' /etc/apt/sources.list
apt update
