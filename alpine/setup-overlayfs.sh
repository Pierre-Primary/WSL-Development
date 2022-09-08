#!/usr/bin/env sh
set -ex

[ "$1" != "-f" ] && [ -e /etc/wsl-init ] && exit

rm -rf /etc/wsl-init
mkdir -p /etc/wsl-init

apk add openrc util-linux procps sudo

echo '%wheel ALL=(ALL) ALL' | tee /etc/sudoers.d/wheel >/dev/null

tee /etc/wsl-init/boot >/dev/null <<"EOF"
#!/usr/bin/env sh

WSL_INIT_CMD="/sbin/init"

if [ "$1" = "-d" ]; then
    exec nohup "$0" >/dev/null 2>&1 &
    exit
fi

# 判断当前进程是否为 Boot 进程（进程号为 1）
# systemd只能在 Boot 进程上运行
if [ $$ -eq "1" ]; then
    rm -rf /overlay

    mkdir -p /rom
    mkdir -p /overlay/lower /overlay/upper /overlay/work

    mount --rbind / /overlay/lower
    mount -t overlay overlay /rom -o lowerdir=/overlay/lower,upperdir=/overlay/upper,workdir=/overlay/work
    mount -t proc proc /rom/proc

    cd /rom
    mkdir -p parent
    pivot_root . parent

    mount --rbind /parent/dev /dev
    mount --rbind /parent/sys /sys
    mount --rbind /parent/run /run
    mount --rbind /parent/tmp /tmp
    mount --rbind /parent/mnt /mnt
    mount --rbind /parent/root /root
    mount --rbind /parent/home /home
    mount --rbind /parent/etc/wsl-init /etc/wsl-init
    mount --rbind /parent/overlay /overlay

    umount -l /parent && rm -rf /parent

    exec $WSL_INIT_CMD
else
    mkdir -p /var/lock
    {
        # 获取锁，避免多进程同步执行
        flock -n 5
        WSL_INIT_HAS_LOCK=$?
        # 判断 systemd 进程是否存在
        WSL_INIT_PID=$(ps -eo pid,args | awk '$2 == "'"$WSL_INIT_CMD"'" { print $1; exit }')
        # systemd 进程已存在，成功退出
        [ -n "$WSL_INIT_PID" ] && exit
        # 获取锁失败，失败退出
        [ $WSL_INIT_HAS_LOCK -eq 1 ] && exit 1
        mkdir -p /var/run
        # 当前进程不是 Boot 进程，使用 unshare 开启新的 mount namespace 和 pid namespace。
        # 若 unshare 命令不存在，请先执行 "apt install util-linux" 安装
        # 使用 /usr/bin/env -i 开启一个无环境变量的新环境，模拟干净的 Boot
        exec /usr/bin/env -i /usr/bin/unshare -mpif --mount-proc -- "$0"
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

WSL_INIT_CMD="/sbin/init"

WSL_INIT_PID=$(ps -eo pid,args | awk '$2 == "'"$WSL_INIT_CMD"'" { print $1; exit }')
if [ -z "$WSL_INIT_PID" ]; then
    sudo /etc/wsl-init/boot -d
    # 循环获取 systemd 进程 id
    # 等两秒
    WSL_INIT_WAIT_COUNT=20
    WSL_INIT_WAIT_TIME=0.1
    WSL_INIT_WAIT_TIMES=0
    while [ $WSL_INIT_WAIT_TIMES -lt $WSL_INIT_WAIT_COUNT ]; do
        WSL_INIT_PID=$(ps -eo pid,args | awk '$2 == "'"$WSL_INIT_CMD"'" { print $1; exit }')
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
    exec /usr/bin/nsenter -a -t "$WSL_INIT_PID" --wd="$(pwd)" -- /bin/sh -c "$*"
fi
EOF
chmod +x /etc/wsl-init/enter

tee /etc/wsl-init/start >/dev/null <<"EOF"
WSL_INIT_CMD="/sbin/init"
WSL_INIT_PID=$(ps -eo pid,args | awk '$2 == "'"$WSL_INIT_CMD"'" { print $1; exit }')
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
