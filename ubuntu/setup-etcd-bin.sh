#!/usr/bin/env bash

# 配置安装版本
ETCD_VER=3.4.20
ETCD_ARCH=amd64

########################################################################################################

DEF_NAME=$(hostname -s)
IP_ADDR=$(ip addr | awk '/inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}')
DEF_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
DEF_LISTEN_PEER_URLS=http://${IP_ADDR:-0.0.0.0}:2380
DEF_INITIAL_CLUSTER_STATE=new

eval set -- "$(getopt -q -o n:q -l name:,listen-peer-urls:,listen-client-urls: -- "$@")"
while [ $# -gt 0 ]; do
    case $1 in
    -q) IS_QUIET=1 ;;
    -n | --name) ETCD_NAME=$2 && shift ;;
    --listen-client-urls) ETCD_LISTEN_CLIENT_URLS=$2 && shift ;;
    *)
        _FLAG=1
        case $1 in
        --advertise-client-urls) ETCD_ADVERTISE_CLIENT_URLS=$2 && shift ;;
        --listen-peer-urls) ETCD_LISTEN_PEER_URLS=$2 && shift ;;
        --initial-advertise-peer-urls) ETCD_INITIAL_ADVERTISE_PEER_URLS=$2 && shift ;;
        --initial-cluster) ETCD_INITIAL_CLUSTER=$2 && shift ;;
        --initial-cluster-token) ETCD_INITIAL_CLUSTER_TOKEN=$2 && shift ;;
        --initial-cluster-state) ETCD_INITIAL_CLUSTER_STATE=$2 && shift ;;
        *) _FLAG=0 ;;
        esac
        [ "$_FLAG" -eq 1 ] && ETCD_CLUSTER=1
        ;;
    esac
    shift
done
if [ -z "$IS_QUIET" ]; then
    [ -z "$ETCD_NAME" ] && read -r -p "Enter Name [$DEF_NAME] " ETCD_NAME
    [ -z "$ETCD_LISTEN_CLIENT_URLS" ] && read -r -p "Enter ListenClientUrls [$DEF_LISTEN_CLIENT_URLS] " ETCD_LISTEN_CLIENT_URLS
    read -r -p "Deploy Cluster? (y|n) [n] " _ETCD_CLUSTER
    if [ "$_ETCD_CLUSTER" = "y" ] || [ "$_ETCD_CLUSTER" = "Y" ]; then
        ETCD_CLUSTER=1
    else
        ETCD_CLUSTER=0
    fi
    if [ "$ETCD_CLUSTER" = "1" ]; then
        [ -z "$ETCD_ADVERTISE_CLIENT_URLS" ] && read -r -p "Enter AdvertiseClientUrls (Use 'ListenClientUrls' values by default) " ETCD_ADVERTISE_CLIENT_URLS
        [ -z "$ETCD_LISTEN_PEER_URLS" ] && read -r -p "Enter ListenPeerUrls [$DEF_LISTEN_PEER_URLS] " ETCD_LISTEN_PEER_URLS
        [ -z "$ETCD_INITIAL_ADVERTISE_PEER_URLS" ] && read -r -p "Enter InitialAdvertisePeerUrls (Use 'ListenPeerUrls' values by default) " ETCD_INITIAL_ADVERTISE_PEER_URLS
        [ -z "$ETCD_INITIAL_CLUSTER" ] && read -r -p "Enter InitialCluster " ETCD_INITIAL_CLUSTER
        [ -z "$ETCD_INITIAL_CLUSTER_TOKEN" ] && read -r -p "Enter InitialClusterToken (Use random values by default) " ETCD_INITIAL_CLUSTER_TOKEN
        [ -z "$ETCD_INITIAL_CLUSTER_STATE" ] && read -r -p "Enter InitialClusterState (new|existing) [$DEF_INITIAL_CLUSTER_STATE] " ETCD_INITIAL_CLUSTER_STATE
    fi
else
    echo "Running Quietly Mode"
fi
[ -z "$ETCD_NAME" ] && ETCD_NAME=$DEF_NAME
[ -z "$ETCD_LISTEN_CLIENT_URLS" ] && ETCD_LISTEN_CLIENT_URLS=$DEF_LISTEN_CLIENT_URLS
[ -z "$ETCD_ADVERTISE_CLIENT_URLS" ] && ETCD_ADVERTISE_CLIENT_URLS=$ETCD_LISTEN_CLIENT_URLS
[ -z "$ETCD_LISTEN_PEER_URLS" ] && ETCD_LISTEN_PEER_URLS=$DEF_LISTEN_PEER_URLS
[ -z "$ETCD_INITIAL_ADVERTISE_PEER_URLS" ] && ETCD_INITIAL_ADVERTISE_PEER_URLS=$ETCD_LISTEN_PEER_URLS
[ -z "$ETCD_INITIAL_CLUSTER" ] && ETCD_INITIAL_CLUSTER="$ETCD_NAME=${ETCD_INITIAL_ADVERTISE_PEER_URLS%%,*}"
[ -z "$ETCD_INITIAL_CLUSTER_TOKEN" ] && ETCD_INITIAL_CLUSTER_TOKEN=$(mktemp -u XXXXXXXX)
[ -z "$ETCD_INITIAL_CLUSTER_STATE" ] && ETCD_INITIAL_CLUSTER_STATE=$DEF_INITIAL_CLUSTER_STATE

########################################################################################################
# 安全安装

type sudo >/dev/null 2>&1 && SUDO="sudo"

$SUDO systemctl stop etcd 2>/dev/null
$SUDO systemctl disable etcd 2>/dev/null

set -x

########################################################################################################
# 准备工作

# 确定安装位置
INSTALL_PATH=/usr/local/bin
SEVICE_PATH=/usr/local/lib/systemd/system

$SUDO apt update

# 安装工具
$SUDO apt install -y \
    ca-certificates \
    curl \
    tar \
    gzip

########################################################################################################

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR" || exit

$SUDO curl -sSL -o etcd.tar.gz https://github.com/etcd-io/etcd/releases/download/v${ETCD_VER}/etcd-v${ETCD_VER}-linux-${ETCD_ARCH}.tar.gz
$SUDO tar -xzf etcd.tar.gz --strip-components=1

$SUDO mkdir -p $INSTALL_PATH
$SUDO install -m 755 etcd etcdctl $INSTALL_PATH

popd || :
$SUDO rm -rf "$TEMP_DIR"

########################################################################################################

$SUDO mkdir -p /etc/containerd

$SUDO mkdir -p /etc/etcd
$SUDO tee /etc/etcd/conf.yml >/dev/null <<EOF
# member
name: $ETCD_NAME
listen-client-urls: $ETCD_LISTEN_CLIENT_URLS
# cluster
advertise-client-urls: $ETCD_ADVERTISE_CLIENT_URLS
listen-peer-urls: $ETCD_LISTEN_PEER_URLS
EOF

[ "$ETCD_CLUSTER" = "1" ] && $SUDO tee -a /etc/etcd/conf.yml >/dev/null <<EOF
initial-advertise-peer-urls: $ETCD_INITIAL_ADVERTISE_PEER_URLS
initial-cluster: $ETCD_INITIAL_CLUSTER
initial-cluster-token: $ETCD_INITIAL_CLUSTER_TOKEN
initial-cluster-state: $ETCD_INITIAL_CLUSTER_STATE
EOF

# $SUDO tee /etc/default/etcd >/dev/null <<EOF
# # [ member ]
# ${ETCD_NAME:+ETCD_NAME="$ETCD_NAME"}
# ${ETCD_LISTEN_CLIENT_URLS:+ETCD_LISTEN_CLIENT_URLS="$ETCD_LISTEN_CLIENT_URLS"}
# ${ETCD_LISTEN_PEER_URLS:+ETCD_LISTEN_PEER_URLS="$ETCD_LISTEN_PEER_URLS"}
# # [ cluster ]
# ${ETCD_ADVERTISE_CLIENT_URLS:+ETCD_ADVERTISE_CLIENT_URLS="$ETCD_ADVERTISE_CLIENT_URLS"}
# EOF

$SUDO mkdir -p $SEVICE_PATH

$SUDO tee $SEVICE_PATH/etcd.service >/dev/null <<EOF
[Unit]
Description=etcd - highly-available key value store
Documentation=https://github.com/coreos/etcd
Documentation=man:etcd
After=network.target
Wants=network-online.target

[Service]
Environment=DAEMON_ARGS=
Environment=ETCD_NAME=%H
Environment=ETCD_DATA_DIR=/var/lib/etcd/default
EnvironmentFile=-/etc/default/%p
Type=notify
# User=etcd
# PermissionsStartOnly=true
# ExecStart=/bin/sh -c "GOMAXPROCS=\$(nproc) $INSTALL_PATH/etcd \$DAEMON_ARGS"
ExecStart=$INSTALL_PATH/etcd \$DAEMON_ARGS --config-file=/etc/etcd/conf.yml
# ExecStart=$INSTALL_PATH/etcd \$DAEMON_ARGS
Restart=on-abnormal
# RestartSec=10s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
$SUDO systemctl daemon-reload

# 启动 etcd 服务，并设置为自启动
$SUDO systemctl enable etcd
$SUDO systemctl start etcd

########################################################################################################
# 生成卸载脚本

$SUDO tee /usr/local/bin/etcd-uninstall <<EOF >/dev/null
#!/usr/bin/env bash
set -x
type sudo >/dev/null 2>&1 && SUDO="sudo"

# 停止并禁用服务
\$SUDO systemctl stop etcd 2>/dev/null
\$SUDO systemctl disable etcd 2>/dev/null

# 删除服务
\$SUDO rm -f $SEVICE_PATH/etcd.service
# 删除服务配置
\$SUDO rm -f /etc/default/etcd
# 删除执行文件
\$SUDO rm -r $INSTALL_PATH/etcd $INSTALL_PATH/etcdctl

if [ "\$1" = "-a" ] || [ "\$1" = "--all" ]; then
    # 清理配置
    \$SUDO rm -rf /etc/etcd
    # 清理数据文件
    \$SUDO rm -rf /var/lib/etcd
fi

# 删除脚本
\$SUDO rm -f /usr/local/bin/etcd-uninstall
EOF
$SUDO chmod +x /usr/local/bin/etcd-uninstall
