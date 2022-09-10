#!/usr/bin/env ash
# shellcheck shell=bash

type apk >/dev/null 2>&1 || exit

set -e
cd "$(dirname "$0")"
alias menu='../base/menu.sh'

set +e
menu -n \
    -t "选择需要切换的仓库：" \
    "中国科技大学" "清华大学" "南京大学" \
    "阿里云" "腾讯云" "华为云"
index=$?
set -e

echo $index

case "$index" in
1) domain=mirrors.ustc.edu.cn ;;
2) domain=mirrors.tuna.tsinghua.edu.cn ;;
3) domain=mirror.nju.edu.cn ;;
4) domain=mirrors.aliyun.com ;;
5) domain=mirrors.cloud.tencent.com ;;
6) domain=repo.huaweicloud.com ;;
*) exit ;;
esac

! [ -e /etc/apk/repositories.bak ] && cp /etc/apk/repositories /etc/apk/repositories.bak

release=$(awk -F'.' ' { print $1"."$2 }' </etc/alpine-release)

tee /etc/apk/repositories <<EOF
http://${domain}/alpine/v${release}/main
http://${domain}/alpine/v${release}/community
EOF
apk update
