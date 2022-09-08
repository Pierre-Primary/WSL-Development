#!/usr/bin/env sh
set -ex

cd "$(dirname "$0")"

SCRIPT_NAME=./"$(basename "$0")"

apk add util-linux
apk add openrc

# 创建隔离环境
if [ "$1" = "--enter" ]; then
    mount -t proc proc /rom/proc

    cd /rom
    mkdir -p parent
    pivot_root . parent

    mount --rbind /parent/dev /dev
    mount --rbind /parent/sys /sys
    mount --rbind /parent/run /run
    mount --rbind /parent/tmp /tmp
    mount --rbind /parent/mnt /mnt
    mount --rbind /parent/overlay /overlay

    umount -l /parent && rm -rf /parent

    exec /sbin/init
elif [ "$1" = "--init" ]; then
    rm -rf /overlay

    mkdir -p /rom
    mkdir -p /overlay/lower /overlay/upper /overlay/work

    mount --rbind / /overlay/lower
    mount -t overlay overlay /rom -o lowerdir=/overlay/lower,upperdir=/overlay/upper,workdir=/overlay/work

    exec /usr/bin/env -i unshare -mupif --mount-proc --propagation=unchanged -- "$SCRIPT_NAME" --enter
else
    pid=$(ps -eo pid,args | awk '$2 ~ /^\/sbin\/init/ { print $1 }')
    if [ -z "$pid" ]; then
        /usr/bin/env -i unshare -mupif --mount-proc --propagation=unchanged -- "$SCRIPT_NAME" --init &
        set +x
        times=0
        while [ $times -lt 10 ]; do
            pid=$(ps -eo pid,args | awk '$2 ~ /^\/sbin\/init/ { print $1 }')
            [ -n "$pid" ] && break
            times=$((times + 1))
            sleep 1
        done
        set -x
        [ -z "$pid" ] && exit
    fi
    exec nsenter -a -t "$pid" --wdns="$(pwd)" -- /bin/sh
fi
