#!/usr/bin/env bash
set -ex

cd "$(dirname "$0")"

if [ "$1" != "--isns" ]; then
    ./setup-systemd.sh
    /etc/wsl-init/enter "sleep 0.5; $0 --isns"
    exit
fi

apt install -y curl gpg lsb-release

mkdir -p /etc/apt/keyrings
rm -f /etc/apt/keyrings/docker.gpg
curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.ustc.edu.cn/docker-ce/linux/debian $(lsb_release -cs) stable" |
    tee /etc/apt/sources.list.d/docker.list >/dev/null
apt update

apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sed -ri '/^ExecStart=\/usr\/bin\/dockerd/c ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375 --containerd=/run/containerd/containerd.sock' /lib/systemd/system/docker.service

systemctl daemon-reload
systemctl restart docker.service
