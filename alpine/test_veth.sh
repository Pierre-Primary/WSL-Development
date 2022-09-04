#! /bin/sh
set -ex

# https://blog.csdn.net/woshaguayi/article/details/114089866
# https://blog.csdn.net/qq_40378034/article/details/123599477

# apk add openrc
apk add util-linux
apk add iproute2

ip link add veth0.0 type veth peer name beth0.0

ip link add name br0 type bridge
ip link set beth0.0 master br0

ip addr add dev br0 192.168.10.1/24

ip link set beth0.0 up
ip link set br0 up

sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

ip netns add n0
ip link set veth0.0 netns n0
ip netns exec n0 ip addr add dev veth0.0 192.168.10.2/24
ip netns exec n0 ip link set veth0.0 up
ip netns exec n0 ip route add default via 192.168.10.1 dev veth0.0

nohup ip netns exec n0 unshare --pid --mount-proc --fork --propagation unchanged -- sleep 3600 >/var/log/test.log 2>&1 &

while true; do
    pid=$(ps -o pid,args | awk '$2 ~ /^sleep/ { print $1 }')
    [ -n "$pid" ] && break
    sleep 0.1
done

exec nsenter --pid --net --mount --target="$pid" --wdns="$(pwd)" -- su
