#! /usr/bin/env bash
shopt -s expand_aliases

set -e

type apt >/dev/null 2>&1 || exit

cd "$(dirname "$0")"
alias menu='../base/menu.sh'

set +e
menu -n \
    -t "选择需要切换的仓库：" \
    "中国科技大学" "清华大学" "南京大学" \
    "阿里云" "腾讯云" "华为云" "网易云"
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
7) domain=mirrors.163.com ;;
*) exit ;;
esac

! [ -e /etc/apt/sources.list.bak ] && cp /etc/apt/sources.list /etc/apt/sources.list.bak

if type lsb_release >/dev/null 2>&1; then
    release=$(lsb_release -cs)
else
    release=$(awk -F'=' ' $1 == "VERSION_CODENAME" { print $2; exit }' </etc/os-release)
fi
tee /etc/apt/sources.list <<EOF
deb http://$domain/ubuntu/ $release main restricted universe multiverse
# deb-src http://$domain/ubuntu/ $release main restricted universe multiverse

deb http://$domain/ubuntu/ $release-security main restricted universe multiverse
# deb-src http://$domain/ubuntu/ $release-security main restricted universe multiverse

# deb http://$domain/ubuntu/ $release-updates main restricted universe multiverse
# deb-src http://$domain/ubuntu/ $release-updates main restricted universe multiverse

# deb http://$domain/ubuntu/ $release-backports main restricted universe multiverse
# deb-src http://$domain/ubuntu/ $release-backports main restricted universe multiverse

# deb http://$domain/ubuntu/ $release-proposed main restricted universe multiverse
# deb-src http://$domain/ubuntu/ $release-proposed main restricted universe multiverse
EOF
apt update
