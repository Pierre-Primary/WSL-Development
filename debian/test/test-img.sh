#!/usr/bin/env sh
set -ex

cd "$(dirname "$0")"

SCRIPT_NAME=./"$(basename "$0")"
INIT_CMD="/sbin/init"

IMG_FILE=../../img/output/alpine-3.16-docker.img

apt install -y systemd procps

if [ "$1" = "--enter" ]; then
    mount -t proc proc /rom/proc

    cd /rom
    mkdir -p parent
    pivot_root . parent

    mount --rbind /parent/dev /dev
    mount --rbind /parent/sys /sys
    mount --rbind /parent/mnt /mnt
    mount --rbind /parent/overlay /overlay

    mount -t tmpfs tmpfs /run
    mount -t tmpfs tmpfs /tmp

    mount --rbind /parent/etc/hosts /etc/hosts
    mount --rbind /parent/etc/resolv.conf /etc/resolv.conf

    umount -l /parent && rm -rf /parent

    sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
    apk update
    apk add openrc

    exec $INIT_CMD
elif [ "$1" = "--init" ]; then
    rm -rf /overlay

    mkdir -p /rom
    mkdir -p /overlay/lower /overlay/upper /overlay/work
    mkdir -p /overlay/over/etc /overlay/over/overlay
    touch /overlay/over/etc/hosts /overlay/over/etc/resolv.conf

    mount -o loop -t ext4 $IMG_FILE /overlay/lower
    mount -t overlay overlay /rom -o lowerdir=/overlay/over:/overlay/lower,upperdir=/overlay/upper,workdir=/overlay/work

    exec /usr/bin/env -i unshare -muipf --mount-proc --propagation=unchanged -- "$SCRIPT_NAME" --enter
else
    INIT_PID=$(ps -eo pid,args | awk '$2 == "'"$INIT_CMD"'" { print $1; exit }')
    if [ -z "$INIT_PID" ]; then
        /usr/bin/env -i unshare -muipf --mount-proc --propagation=unchanged -- "$SCRIPT_NAME" --init &
        set +x
        WAIT_TIMES=0
        while [ $WAIT_TIMES -lt 10 ]; do
            INIT_PID=$(ps -eo pid,args | awk '$2 == "'"$INIT_CMD"'" { print $1; exit }')
            [ -n "$INIT_PID" ] && break
            WAIT_TIMES=$((WAIT_TIMES + 1))
            sleep 1
        done
        set -x
        [ -z "$INIT_PID" ] && exit
    fi
    exec nsenter -a -t "$INIT_PID" -- /bin/sh -c "cd $(pwd); exec /bin/ash"
fi
