#!/usr/bin/env ash
# shellcheck shell=dash
set -ex

# https://blog.csdn.net/woshaguayi/article/details/114089866
# https://blog.csdn.net/qq_40378034/article/details/123599477

ciptables() {
    check=$(echo "$@" | sed -e 's/-A/-C/g')
    if ! eval "$check" >/dev/null 2>&1; then
        "$@"
    fi
}

cd "$(dirname "$0")"

SCRIPT_NAME=./"$(basename "$0")"

if [ "$1" = "--enter" ]; then
    exec /bin/ash
elif [ "$1" = "--init" ]; then
    exec unshare -muipf --mount-proc --propagation=unchanged -- "$SCRIPT_NAME" --enter
else
    apk add util-linux iproute2 iptables

    set +e
    ip netns pids n0 | xargs -I{} kill -SIGTERM {}
    ip netns del n0
    ip link del beth0.0
    ip link del br0
    set -e

    ip link add veth0.0 type veth peer name beth0.0
    ip link add name br0 type bridge
    ip link set beth0.0 master br0

    ip addr add dev br0 192.168.10.1/24

    ip link set beth0.0 up
    ip link set br0 up

    sysctl -w net.ipv4.ip_forward=1
    ciptables iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    ip netns add n0
    ip link set veth0.0 netns n0
    ip netns exec n0 ip addr add dev veth0.0 192.168.10.2/24
    ip netns exec n0 ip link set veth0.0 up
    ip netns exec n0 ip route add default via 192.168.10.1 dev veth0.0
    ip netns exec n0 "$SCRIPT_NAME" --init
fi
