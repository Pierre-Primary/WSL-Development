#! /bin/sh
set -x

apk add util-linux
apk add openrc

rm -rf /overlay
mkdir -p /overlay/upper
mkdir -p /overlay/work
mkdir -p /overlay/merged

while mountpoint /overlay/merged >/dev/null 2>&1; do
    umount -Rf /overlay/merged
done

mount -t overlay none /overlay/merged -o lowerdir=/,upperdir=/overlay/upper,workdir=/overlay/work
mount -t proc proc /overlay/merged/proc
mount --rbind /dev /overlay/merged/dev
mount --rbind /sys /overlay/merged/sys

nohup /usr/bin/env -i /usr/bin/unshare --uts --mount-proc --pid --net --ipc --root=/overlay/merged --fork --propagation=unchanged -- /sbin/init >/dev/null 2>&1 &

while true; do
    pid=$(ps -o pid,args | awk '$2 ~ /^\/sbin\/init/ { print $1 }')
    [ -n "$pid" ] && break
    sleep 0.1
done

exec /usr/bin/env -i /usr/bin/nsenter --uts --mount --pid --net --ipc --target="$pid" -- /usr/sbin/chroot /overlay/merged
# exec /usr/bin/env -i /usr/bin/nsenter --uts --mount --pid --net --ipc --root=/overlay/merged --target="$pid" --wdns=/
