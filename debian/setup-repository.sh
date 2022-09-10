#! /usr/bin/env bash
shopt -s expand_aliases

type apt >/dev/null 2>&1 || exit

set -e
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
deb http://$domain/debian/ $release main contrib non-free
# deb-src http://$domain/debian/ $release main contrib non-free

deb http://$domain/debian/ $release-updates main contrib non-free
# deb-src http://$domain/debian/ $release-updates main contrib non-free

# deb http://$domain/debian/ $release-backports main contrib non-free
# deb-src http://$domain/debian/ $release-backports main contrib non-free

# deb http://$domain/debian-security $release-security main contrib non-free
# deb-src http://$domain/debian-security $release-security main contrib non-free
EOF
apt update
