#!/usr/bin/env bash
set -ex

[ "$1" != "-f" ] && [ -e /etc/wsl-init ] && exit

rm -rf /etc/wsl-init
mkdir -p /etc/wsl-init

apt install -y systemd daemonize procps sudo

echo '%sudo ALL=(ALL) ALL' | tee /etc/sudoers.d/sudo >/dev/null

tee /etc/wsl-init/boot >/dev/null <<"EOF"
#!/usr/bin/env sh

WSL_INIT_CMD="/lib/systemd/systemd --system-unit=basic.target"

if [ "$1" = "-d" ]; then
    if [ -x /usr/sbin/daemonize ]; then
        WSL_INIT_DAEMONIZE=/usr/sbin/daemonize
    elif [ -x /usr/bin/daemonize ]; then
        WSL_INIT_DAEMONIZE=/usr/bin/daemonize
    fi
    if [ -n "$WSL_INIT_DAEMONIZE" ]; then
        exec $WSL_INIT_DAEMONIZE "$0"
        exit
    fi
fi

# 判断当前进程是否为 Boot 进程（进程号为 1）
# systemd只能在 Boot 进程上运行
if [ $$ -eq "1" ]; then
    exec $WSL_INIT_CMD
else
    mkdir -p /var/lock
    {
        # 获取锁，避免多进程同步执行
        flock -n 5
        WSL_INIT_HAS_LOCK=$?
        # 判断 systemd 进程是否存在
        WSL_INIT_PID=$(ps -eo pid,args | awk '$2" "$3 == "'"$WSL_INIT_CMD"'" { print $1; exit }')
        # systemd 进程已存在，成功退出
        [ -n "$WSL_INIT_PID" ] && exit
        # 获取锁失败，失败退出
        [ $WSL_INIT_HAS_LOCK -eq 1 ] && exit 1
        mkdir -p /var/run
        # 当前进程不是 Boot 进程，使用 unshare 开启新的 mount namespace 和 pid namespace。
        # 若 unshare 命令不存在，请先执行 "apt install util-linux" 安装
        # 使用 /usr/bin/env -i 开启一个无环境变量的新环境，模拟干净的 Boot
        exec /usr/bin/env -i /usr/bin/unshare -mpf --mount-proc -- "$0"
    } 5<>/var/lock/wsl-init.lock
fi
EOF
chmod +x /etc/wsl-init/boot

tee /etc/wsl-init/enter-core >/dev/null <<"EOF"
#!/usr/bin/env sh
exec /usr/bin/env -i /usr/bin/nsenter -a -t "$1" -- su - $SUDO_USER
EOF
chmod +x /etc/wsl-init/enter-core

tee /etc/wsl-init/enter >/dev/null <<"EOF"
#!/usr/bin/env sh

WSL_INIT_CMD="/lib/systemd/systemd --system-unit=basic.target"

WSL_INIT_PID=$(ps -eo pid,args | awk '$2" "$3 == "'"$WSL_INIT_CMD"'" { print $1; exit }')
if [ -z "$WSL_INIT_PID" ]; then
    sudo /etc/wsl-init/boot -d
    # 循环获取 systemd 进程 id
    # 等两秒
    WSL_INIT_WAIT_COUNT=20
    WSL_INIT_WAIT_TIME=0.1
    WSL_INIT_WAIT_TIMES=0
    while [ $WSL_INIT_WAIT_TIMES -lt $WSL_INIT_WAIT_COUNT ]; do
        WSL_INIT_PID=$(ps -eo pid,args | awk '$2" "$3 == "'"$WSL_INIT_CMD"'" { print $1; exit }')
        [ -n "$WSL_INIT_PID" ] && break
        WSL_INIT_WAIT_TIMES=$((WSL_INIT_WAIT_TIMES + 1))
        sleep $WSL_INIT_WAIT_TIME
    done
    # PID 为空表示 systemd 没有启动
    if [ -z "$WSL_INIT_PID" ]; then
        echo "systemd is not started"
        exit
    fi
fi

if [ $# -eq 0 ]; then
    # 保存环境变量
    export >"$HOME/.wsl-init.env"
    # 进入 namespace
    # 默认允许所有用户切换 namespace。详情查看 /etc/sudoers.d/wsl-init
    exec sudo /etc/wsl-init/enter-core "$WSL_INIT_PID"
else
    # 在 namespace 中执行命令
    # 避免普通用户通过此方式执行危险命令，不默认提供 sudo 权限
    exec /usr/bin/nsenter -a -t "$WSL_INIT_PID" -- /bin/sh -c "cd $(pwd); /bin/sh -c \"$*\""
fi
EOF
chmod +x /etc/wsl-init/enter

tee /etc/wsl-init/start >/dev/null <<"EOF"
WSL_INIT_CMD="/lib/systemd/systemd --system-unit=basic.target"
WSL_INIT_PID=$(ps -eo pid,args | awk '$2" "$3 == "'"$WSL_INIT_CMD"'" { print $1; exit }')
if [ -z "$WSL_INIT_PID" ] || [ "$WSL_INIT_PID" -ne 1 ]; then
    exec /etc/wsl-init/enter
elif [ -r "$HOME/.wsl-init.env" ]; then
    set -a
    . "$HOME/.wsl-init.env"
    set +a
    rm -f "$HOME/.wsl-init.env"
    [ -n "$PWD" ] && cd $PWD
    unset OLDPWD
fi
EOF
chmod +x /etc/wsl-init/start
ln -sf /etc/wsl-init/start /etc/profile.d/zzz-wsl-init-start.sh

tee /etc/wsl-init/sudoer >/dev/null <<EOF
ALL ALL=(root) NOPASSWD: /etc/wsl-init/boot
ALL ALL=(root) NOPASSWD: /etc/wsl-init/enter-core
EOF
ln -sf /etc/wsl-init/sudoer /etc/sudoers.d/wsl-init
