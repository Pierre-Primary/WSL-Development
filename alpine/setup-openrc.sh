#!/bin/sh
set -ex

apk add openrc

##############################################################################################
# openrc 依靠 inittab
# WSL中初始进程 "/init" 无法启动 inittab，需要重新执行 "/sbin/init"
# "/sbin/init" 必须做为初始进程 (PID 1) 运行，使用 namespace 技术
# 依赖 util-linux 软件包实现 namespace
# 依赖 nohup 和 & 实现后台运行

apk add util-linux

mkdir -p /etc/wsl

cat <<"EOF" | tee /etc/wsl/wsl-init
#!/bin/sh
set -eu
if [ $$ -ne "1" ]; then
    exec nohup sh -c "echo \$$ >/run/wsl-init.pid; exec /usr/bin/env -i /usr/bin/unshare --pid --mount-proc --fork --propagation unchanged -- ${0}" >/var/log/wsl-init.out 2>&1 &
    exit
fi
exec /sbin/init
EOF
chmod +x /etc/wsl/wsl-init

# wel.conf  boot.command
cat <<EOF | tee /etc/wsl.conf
[boot]
command = /etc/wsl/wsl-init
EOF

##############################################################################################
# shell 会话自动进入 namespace

cat <<"EOF" | tee /etc/wsl/wsl-nsenter-core
#!/bin/sh
set -e
exec /usr/bin/nsenter -p -m -t "$1" --wdns="$(pwd)" -- su "${2:-root}"
EOF
chmod +x /etc/wsl/wsl-nsenter-core

apk add sudo
echo "ALL ALL=(root) NOPASSWD: /etc/wsl/wsl-nsenter-core" >/etc/sudoers.d/wsl-nsenter

cat <<"EOF" | tee /etc/wsl/wsl-nsenter
#!/bin/sh
set -e
if [ -r /run/wsl-init.pid ]; then
    parent="$(cat /run/wsl-init.pid)"
    pid="$(ps -o pid,ppid,comm | awk '$2 == "'"${parent}"'" && $3 ~ /^init/ { print $1 }')"
    if [ -n "$pid" ] && [ "$pid" -ne 1 ]; then
        if [ "$USER" == "root" ]; then
            exec /etc/wsl/wsl-nsenter-core "$pid"
        elif type -t /usr/bin/sudo >/dev/null; then        
            [ -f "$HOME/.wsl-nsenter.env" ] && rm "$HOME/.wsl-nsenter.env"
            export > "$HOME/.wsl-nsenter.env"
            exec sudo /etc/wsl/wsl-nsenter-core "$pid" "$USER"
        fi
    fi
fi
if [ -f "$HOME/.wsl-nsenter.env" ]; then
  set -a
  source "$HOME/.wsl-nsenter.env"
  set +a
  rm "$HOME/.wsl-nsenter.env"
fi
EOF
chmod +x /etc/wsl/wsl-nsenter
ln -s /etc/wsl/wsl-nsenter /etc/profile.d/00-wsl-nsenter.sh
