#! /bin/sh
set -x

apk add util-linux
apk add openrc
apk --root=/rom add util-linux
apk --root=/rom add openrc

cat <<EOF | tee /etc/wsl.conf
[automount]
root = /mnt/host
crossDistro = true
options = "metadata"
EOF

# mkdir -p /overlay/root/mnt/wsl
# mount --bind / /overlay/root/mnt/wsl
# mkdir -p /overlay/root/mnt/c
# mount --bind /mnt/c /overlay/root/mnt/c
# mount -t proc proc /overlay/merged/proc -o rw,nosuid,nodev,noexec,noatime
# cp /etc/hosts /overlay/merged/etc/hosts
# cp /etc/resolv.conf /overlay/merged/etc/resolv.conf
# mount --rbind /dev /overlay/merged/dev
# mount --rbind /sys /overlay/merged/sys

# exec /usr/bin/env -i /usr/bin/unshare -muinpf --propagation=unchanged --kill-child=SIGTERM -- sh -c "
# exec unshare -muinpf --root=/overlay/root --propagation=unchanged --kill-child=SIGTERM -- sh -c "

if [ -d /overlay/root ]; then
    while mountpoint /overlay/root >/dev/null 2>&1; do
        umount -Rlvf /overlay/root
    done
fi
rm -rf /overlay

mkdir -p /overlay/upper
mkdir -p /overlay/work
mkdir -p /overlay/root
mount -t overlay none /overlay/root -o lowerdir=/rom,upperdir=/overlay/upper,workdir=/overlay/work

/usr/bin/env -i /usr/sbin/chroot /overlay/root /usr/bin/unshare -muinpf --propagation=unchanged -- sh -c "
mount -t proc proc /proc -o rw,nosuid,nodev,noexec,noatime
exec ash
"

# # mount -t overlay none /overlay/root -o lowerdir=/rom,upperdir=/overlay/upper,workdir=/overlay/work
# mkdir -p /overlay/root/parent-distro
# mount --rbind / /overlay/root/parent-distro
# mount -o loop,ro,relatime -t ext4 /mnt/host/e/VM/Images/rom.img /overlay/root
# mount -t sysfs sysfs /overlay/root/sys -o rw,nosuid,nodev,noexec,noatime;
# mount -t cgroup cgroup /sys/fs/cgroup -o rw,nosuid,nodev,noexec,noatime;
# mount -t devtmpfs none /dev -o rw,nosuid,relatime,size=5091180k,nr_inodes=1272795,mode=755;
# nsenter -a -t
# nohup /usr/bin/env -i /usr/bin/unshare --uts --mount-proc --pid --net --ipc --root=/overlay/merged --fork --propagation=unchanged -- /sbin/init >/dev/null 2>&1 &

# while true; do
#     pid=$(ps -o pid,args | awk '$2 ~ /^\/sbin\/init/ { print $1 }')
#     [ -n "$pid" ] && break
#     sleep 0.1
# done

# echo "$pid"

# exec /usr/bin/env -i /usr/bin/nsenter --uts --mount --pid --net --ipc --target="$pid" -- /usr/sbin/chroot /overlay/merged
# exec /usr/bin/env -i /usr/bin/nsenter --uts --mount --pid --net --ipc --root=/overlay/merged --wdns=/ --target=50
