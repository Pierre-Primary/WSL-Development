#!/usr/bin/env ash
# shellcheck shell=bash
set -ex

# 切换 bash，并安装 completion
apk add shadow
apk add bash bash-completion
usermod --shell /bin/bash root

# 设置 PS1 样式
cat >/etc/profile.d/bash_theme.sh <<EOF
if [ "x\${BASH_VERSION-}" != x ]; then
    [ "$(id -u)" -eq 0 ] && PS_TAG='#' || PS_TAG='$'
    export PS1="\[\e[0;34m\]#\[\e[0m\] \[\e[0;36m\]\u\[\e[0m\] \[\e[02m\]@\[\e[0m\] \[\e[0;32m\]\h\[\e[0m\] \[\e[02m\]in\[\e[0m\] \[\e[0;33m\]\w\[\e[0m\] \[\e[02m\][\t]\[\e[0m\]\n\[\e[0;31m\]\$PS_TAG\[\e[0m\] "
fi
EOF
