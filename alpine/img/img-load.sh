#!/usr/bin/env sh
set -ex

cd "$(dirname "$0")"

if [ "$1" = "--enter" ]; then
    PWD_PATH=$(pwd)

    mount -t proc proc /rom/root/proc

    cd /rom/root
    mkdir -p parent
    pivot_root . parent

    mount --rbind /parent/dev /dev
    mount --rbind /parent/sys /sys
    mount --rbind /parent/mnt /mnt
    mount --rbind /parent/etc/hosts /etc/hosts
    mount --rbind /parent/etc/resolv.conf /etc/resolv.conf
    umount -l /parent && rm -rf /parent

    cd "$PWD_PATH"

    sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
    apk update
    apk add openrc

    exec /sbin/init
elif [ "$1" = "--init" ]; then
    rm -rf /rom
    mkdir -p /rom/rom /rom/root /rom/over /rom/upper /rom/work
    mkdir -p /rom/over/etc
    touch /rom/over/etc/hosts /rom/over/etc/resolv.conf
    mount -t ext4 ./output/alpine-3.16-docker.img /rom/rom -o loop
    mount -t overlay overlay /rom/root -o lowerdir=/rom/over:/rom/rom,upperdir=/rom/upper,workdir=/rom/work
    exec /usr/bin/env -i unshare -muipf --mount-proc --propagation=unchanged -- "$0" --enter
else
    pid=$(ps -eo pid,args | awk '$2 ~ /^\/sbin\/init/ { print $1 }')
    if [ -z "$pid" ]; then
        nohup /usr/bin/env -i unshare -muipf --mount-proc --propagation=unchanged -- "$0" --init >/dev/null 2>&1 &
        set +x
        times=0
        while [ $times -lt 10 ]; do
            pid=$(ps -eo pid,args | awk '$2 ~ /^\/sbin\/init/ { print $1 }')
            [ -n "$pid" ] && break
            times=$((times + 1))
            sleep 1
        done
        set -x
    fi
    exec nsenter -a -t "$pid" --wdns="$(pwd)" -- /bin/sh
fi
