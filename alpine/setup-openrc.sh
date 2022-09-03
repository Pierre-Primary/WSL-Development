#!/usr/bin/env sh
set -ex

apk add openrc

##############################################################################################
# openrc 依靠 inittab
# WSL中初始进程 "/init" 无法启动 inittab，需要重新执行 "/sbin/init"
# "/sbin/init" 必须做为初始进程 (PID 1) 运行，使用 namespace 技术
# 依赖 util-linux  软件包实现 namespace

apk add util-linux

mkdir -p /etc/wsl

cat <<"EOF" | tee /etc/wsl/wsl-init
#!/bin/sh
set -eu
if [ $$ -ne "1" ]; then
    echo $$ > /run/wsl-init.pid
    exec /usr/bin/env -i /usr/bin/unshare --pid --mount-proc --fork --propagation unchanged -- ${0}
    exit
fi
exec /sbin/init
EOF
chmod +x /etc/wsl/wsl-init

cat <<EOF | tee /etc/wsl.conf
[boot]
command = /etc/wsl/wsl-init

# [user]
# default = test
EOF

##############################################################################################
# shell 会话自动进入 namespace

cat <<"EOF" | tee /etc/wsl/wsl-nsenter
#!/bin/sh
set -e
if [ "$USER" == "root" ] && [ -r /run/wsl-init.pid ]; then
    parent="$(cat /run/wsl-init.pid)"
    pid="$(ps -o pid,ppid,comm | awk '$2 == "'"${parent}"'" && $3 ~ /^init/ { print $1 }')"
    if [ -n "${pid}" ] && [ "$pid" -ne 1 ]; then
        exec /usr/bin/nsenter -p -m -t "${pid}" --wdns="$(pwd)" -- su "${1:-root}"
    fi
fi
EOF
chmod +x /etc/wsl/wsl-nsenter
ln -s /etc/wsl/wsl-nsenter /etc/profile.d/00-wsl-nsenter.sh

##############################################################################################
# 非root用户，权限处理

apk add sudo
echo "ALL ALL=(root) NOPASSWD: /etc/wsl/wsl-nsenter" >/etc/sudoers.d/wsl-nsenter-rootless

cat <<"EOF" | tee /etc/wsl/wsl-nsenter-rootless
#!/bin/sh
set -e
if [ "$USER" != "root" ] && type -t /usr/bin/sudo >/dev/null; then
    exec sudo /etc/wsl/wsl-nsenter "$USER"
fi
EOF
chmod +x /etc/wsl/wsl-nsenter-rootless
ln -s /etc/wsl/wsl-nsenter-rootless /etc/profile.d/00-wsl-nsenter-rootless.sh
