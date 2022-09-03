#!/usr/bin/env bash
set -ex

apk add openrc

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

cat <<"EOF" | tee /etc/wsl/wsl-nsenter
#!/bin/sh
set -eu
if [ -r /run/wsl-init.pid ]; then
    parent="$(cat /run/wsl-init.pid)"
    pid="$(ps -o pid,ppid,comm | awk '$2 == "'"${parent}"'" && $3 ~ /^init/ { print $1 }')"
    if [ -n "${pid}" ] && [ "$pid" -ne 1 ]; then
        exec /usr/bin/nsenter -p -m -t "${pid}" --wdns="$(pwd)" -- su "$USER"
    fi
fi
EOF
chmod +x /etc/wsl/wsl-nsenter
ln -s /etc/wsl/wsl-nsenter /etc/profile.d/00-wsl-nsenter.sh

cat <<EOF | tee -a /etc/wsl.conf
[boot]
command = "/etc/wsl/wsl-init"
EOF
