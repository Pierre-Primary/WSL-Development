#!/usr/bin/env bash

# 配置安装版本
ETCD_VER=${ETCD_VER:-3.4.20}
ETCD_ARCH=${ETCD_ARCH:-amd64}

########################################################################################################
# 参数处理

IP_ADDR=$(ip addr | awk '/inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2); exit }')

DEF_NAME=$(hostname -s)
DEF_LISTEN_CLIENT_ADDRESS="0.0.0.0"
DEF_LISTEN_CLIENT_PORT=2379
DEF_LISTEN_PEER_ADDRESS="0.0.0.0"
DEF_LISTEN_PEER_PORT=2380
DEF_ADVERTISE_ADDRESS="${IP_ADDR:-0.0.0.0}"
DEF_CLUSTER_TOKEN=$(mktemp -u XXXXXXXX)
DEF_CLUSTER_STATE=new

eval set -- "$(
    getopt -q \
        -o n:l:p:q \
        -l name:,listen-client-address:,listen-client-port:,listen-peer-address:,listen-peer-port:,cluster,advertise-client-address:,advertise-peer-address:,cluster-list:,cluster-token:,cluster-state: \
        -- "$@"
)"
while [ $# -gt 0 ]; do
    case $1 in
    -q) OPT_IS_QUIET=1 ;;
    -n | --name) OPT_NAME=$2 && shift ;;
    -l | --listen-client-address) OPT_LISTEN_CLIENT_ADDRESS=$2 && shift ;;
    -p | --listen-client-port) OPT_LISTEN_CLIENT_PORT=$2 && shift ;;
    --listen-peer-address) OPT_LISTEN_PEER_ADDRESS=$2 && shift ;;
    --listen-peer-port) OPT_LISTEN_PEER_PORT=$2 && shift ;;
    *)
        _FLAG=1
        case $1 in
        --cluster) OPT_IS_CLUSTER=1 ;;
        --advertise-client-address) OPT_ADVERTISE_CLIENT_ADDRESS=$2 && shift ;;
        --advertise-peer-address) OPT_ADVERTISE_PEER_ADDRESS=$2 && shift ;;
        --cluster-list) OPT_CLUSTER_LIST=$2 && shift ;;
        --cluster-token) OPT_CLUSTER_TOKEN=$2 && shift ;;
        --cluster-state) OPT_CLUSTER_STATE=$2 && shift ;;
        *) _FLAG=0 ;;
        esac
        [ "$_FLAG" -eq 1 ] && OPT_IS_CLUSTER=1
        ;;
    esac
    shift
done
if [ -z "$OPT_IS_QUIET" ]; then
    [ -z "$OPT_NAME" ] && read -r -p "Enter Name [$DEF_NAME] " OPT_NAME
    [ -z "$OPT_NAME" ] && OPT_NAME=$DEF_NAME

    [ -z "$OPT_LISTEN_CLIENT_ADDRESS" ] && read -r -p "Enter Listen Client Address [$DEF_LISTEN_CLIENT_ADDRESS] " OPT_LISTEN_CLIENT_ADDRESS
    [ -z "$OPT_LISTEN_CLIENT_ADDRESS" ] && OPT_LISTEN_CLIENT_ADDRESS=$DEF_LISTEN_CLIENT_ADDRESS

    [ -z "$OPT_LISTEN_CLIENT_PORT" ] && read -r -p "Enter Listen Client Port [$DEF_LISTEN_CLIENT_PORT] " OPT_LISTEN_CLIENT_PORT
    [ -z "$OPT_LISTEN_CLIENT_PORT" ] && OPT_LISTEN_CLIENT_PORT=$DEF_LISTEN_CLIENT_PORT

    [ -z "$OPT_LISTEN_PEER_ADDRESS" ] && read -r -p "Enter Listen Peer Address [$DEF_LISTEN_PEER_ADDRESS] " OPT_LISTEN_PEER_ADDRESS
    [ -z "$OPT_LISTEN_PEER_ADDRESS" ] && OPT_LISTEN_PEER_ADDRESS=$DEF_LISTEN_PEER_ADDRESS

    [ -z "$OPT_LISTEN_PEER_PORT" ] && read -r -p "Enter Listen Peer Port [$DEF_LISTEN_PEER_PORT] " OPT_LISTEN_PEER_PORT
    [ -z "$OPT_LISTEN_PEER_PORT" ] && OPT_LISTEN_PEER_PORT=$DEF_LISTEN_PEER_PORT

    read -r -p "Deploy Cluster? (y|n) [n] " _OPT_CLUSTER
    if echo "$_OPT_CLUSTER" | grep -qwi "y"; then
        OPT_IS_CLUSTER=1
        [ -z "$OPT_ADVERTISE_CLIENT_ADDRESS" ] && read -r -p "Enter Advertise Client Address [$DEF_ADVERTISE_ADDRESS] " OPT_ADVERTISE_CLIENT_ADDRESS
        [ -z "$OPT_ADVERTISE_CLIENT_ADDRESS" ] && OPT_ADVERTISE_CLIENT_ADDRESS=$DEF_ADVERTISE_ADDRESS

        [ -z "$OPT_ADVERTISE_PEER_ADDRESS" ] && read -r -p "Enter Advertise Peer Address [$DEF_ADVERTISE_ADDRESS] " OPT_ADVERTISE_PEER_ADDRESS
        [ -z "$OPT_ADVERTISE_PEER_ADDRESS" ] && OPT_ADVERTISE_PEER_ADDRESS=$DEF_ADVERTISE_ADDRESS

        DEF_CLUSTER_LIST="$OPT_NAME=http://${OPT_ADVERTISE_PEER_ADDRESS}:${OPT_LISTEN_PEER_PORT}"
        [ -z "$OPT_CLUSTER_LIST" ] && read -r -p "Enter Cluster List [$DEF_CLUSTER_LIST] " OPT_CLUSTER_LIST
        [ -z "$OPT_CLUSTER_LIST" ] && OPT_CLUSTER_LIST=$DEF_CLUSTER_LIST

        [ -z "$OPT_CLUSTER_TOKEN" ] && read -r -p "Enter Cluster Token (Use random values by default) [$DEF_CLUSTER_TOKEN] " OPT_CLUSTER_TOKEN
        [ -z "$OPT_CLUSTER_TOKEN" ] && OPT_CLUSTER_TOKEN=$DEF_CLUSTER_TOKEN

        [ -z "$OPT_CLUSTER_STATE" ] && read -r -p "Enter Cluster State (new|existing) [$DEF_CLUSTER_STATE] " OPT_CLUSTER_STATE
        [ -z "$OPT_CLUSTER_STATE" ] && OPT_CLUSTER_STATE=$DEF_CLUSTER_STATE
    fi
fi
[ -z "$OPT_NAME" ] && OPT_NAME=$DEF_NAME
[ -z "$OPT_LISTEN_CLIENT_ADDRESS" ] && OPT_LISTEN_CLIENT_ADDRESS=$DEF_LISTEN_CLIENT_ADDRESS
[ -z "$OPT_LISTEN_CLIENT_PORT" ] && OPT_LISTEN_CLIENT_PORT=$DEF_LISTEN_CLIENT_PORT
[ -z "$OPT_LISTEN_PEER_ADDRESS" ] && OPT_LISTEN_PEER_ADDRESS=$DEF_LISTEN_PEER_ADDRESS
[ -z "$OPT_LISTEN_PEER_PORT" ] && OPT_LISTEN_PEER_PORT=$DEF_LISTEN_PEER_PORT
[ -z "$OPT_ADVERTISE_CLIENT_ADDRESS" ] && OPT_ADVERTISE_CLIENT_ADDRESS=$DEF_ADVERTISE_ADDRESS
[ -z "$OPT_ADVERTISE_PEER_ADDRESS" ] && OPT_ADVERTISE_PEER_ADDRESS=$DEF_ADVERTISE_ADDRESS
[ -z "$OPT_CLUSTER_LIST" ] && OPT_CLUSTER_LIST="$OPT_NAME=http://${OPT_ADVERTISE_PEER_ADDRESS}:${OPT_LISTEN_PEER_PORT}"
[ -z "$OPT_CLUSTER_TOKEN" ] && OPT_CLUSTER_TOKEN=$DEF_CLUSTER_TOKEN
[ -z "$OPT_CLUSTER_STATE" ] && OPT_CLUSTER_STATE=$DEF_CLUSTER_STATE

ETCD_NAME=$OPT_NAME
ETCD_LISTEN_CLIENT_URLS="http://${OPT_LISTEN_CLIENT_ADDRESS}:${OPT_LISTEN_CLIENT_PORT}"
ETCD_LISTEN_PEER_URLS="http://${OPT_LISTEN_PEER_ADDRESS}:${OPT_LISTEN_PEER_PORT}"
ETCD_ADVERTISE_CLIENT_URLS="http://${OPT_ADVERTISE_CLIENT_ADDRESS}:${OPT_LISTEN_CLIENT_PORT}"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${OPT_ADVERTISE_PEER_ADDRESS}:${OPT_LISTEN_PEER_PORT}"
ETCD_INITIAL_CLUSTER=$OPT_CLUSTER_LIST
ETCD_INITIAL_CLUSTER_TOKEN=$OPT_CLUSTER_TOKEN
ETCD_INITIAL_CLUSTER_STATE=$OPT_CLUSTER_STATE

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
# 安装 etcd

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR" >/dev/null || exit

$SUDO curl -sSL -o etcd.tar.gz https://github.com/etcd-io/etcd/releases/download/v${ETCD_VER}/etcd-v${ETCD_VER}-linux-${ETCD_ARCH}.tar.gz
$SUDO tar -xzf etcd.tar.gz --strip-components=1

$SUDO mkdir -p $INSTALL_PATH
$SUDO install -m 755 etcd etcdctl $INSTALL_PATH

popd >/dev/null || :
$SUDO rm -rf "$TEMP_DIR"

########################################################################################################
# 配置 etcd

# $SUDO mkdir -p /etc/etcd
# $SUDO tee /etc/etcd/conf.yml >/dev/null <<EOF
# EOF

# etcd 软件配置
$SUDO mkdir -p /etc/default
cat <<EOF | $SUDO tee /etc/default/etcd >/dev/null
# [ member ]
ETCD_NAME="$ETCD_NAME"
ETCD_LISTEN_CLIENT_URLS="$ETCD_LISTEN_CLIENT_URLS"
ETCD_LISTEN_PEER_URLS="$ETCD_LISTEN_PEER_URLS"
# [ cluster ]
ETCD_ADVERTISE_CLIENT_URLS="$ETCD_ADVERTISE_CLIENT_URLS"
EOF
[ "$OPT_IS_CLUSTER" = "1" ] && cat <<EOF | $SUDO tee -a /etc/default/etcd >/dev/null
ETCD_INITIAL_ADVERTISE_PEER_URLS="$ETCD_INITIAL_ADVERTISE_PEER_URLS"
ETCD_INITIAL_CLUSTER="$ETCD_INITIAL_CLUSTER"
ETCD_INITIAL_CLUSTER_TOKEN="$ETCD_INITIAL_CLUSTER_TOKEN"
ETCD_INITIAL_CLUSTER_STATE="$ETCD_INITIAL_CLUSTER_STATE"
EOF

# etcd 服务配置
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
# ExecStart=$INSTALL_PATH/etcd \$DAEMON_ARGS --config-file=/etc/etcd/conf.yml
ExecStart=$INSTALL_PATH/etcd \$DAEMON_ARGS
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
