#! /bin/sh
set -x

cd /

apk add util-linux
apk add openrc

# 创建隔离环境
/usr/bin/env -i unshare -mupf --kill-child=SIGTERM --propagation=unchanged -- sh -c "
mkdir -p /overlay/upper /overlay/work /rom
mount -t overlay overlay /rom -o lowerdir=/,upperdir=/overlay/upper,workdir=/overlay/work
mount -t proc proc /rom/proc -o rw,nosuid,nodev,noexec,noatime
mount --rbind /dev /rom/dev
mount --rbind /sys /rom/sys
mount -t tmpfs tmpfs /rom/tmp
mount -t tmpfs tmpfs /rom/run

cd /rom
mkdir -p old-root
pivot_root . old-root
umount -l /old-root && rm -rf /old-root
exec /sbin/init
" >/dev/null 2>&1 &

times=0
while true; do
    pid=$(ps -o pid,args | awk '$2 ~ /^\/sbin\/init/ { print $1 }')
    [ -n "$pid" ] && break
    times=$((times + 1))
    [ "$times" -ge 10 ] && exit 1
    sleep 0.1
done

exec /usr/bin/env -i nsenter -a -t "$pid"
