#!/usr/bin/env bash

# 配置安装版本
FLANNEL_VER=${FLANNEL_VER:-0.19.2}
FLANNEL_ARCH=${FLANNEL_ARCH:-amd64}

########################################################################################################
# 参数处理

IP_ADDR=$(ip addr | awk '/inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2); exit }')

DEF_ETCD_ENDPOINTS="http://127.0.0.1:2379"
DEF_ETCD_PREFIX="/coreos.com/network"
DEF_IFACE="$IP_ADDR"

eval set -- "$(getopt -q -o q -l etcd-endpoints:,etcd-prefix:,iface:,if: -- "$@")"
while [ $# -gt 0 ]; do
    case $1 in
    -q) OPT_IS_QUIET=1 ;;
    --etcd-endpoints) OPT_ETCD_ENDPOINTS=$2 && shift ;;
    --etcd-prefix) OPT_ETCD_PREFIX=$2 && shift ;;
    --iface | --if) OPT_IFACE=$2 && shift ;;
    esac
    shift
done
if [ -z "$OPT_IS_QUIET" ]; then
    [ -z "$OPT_ETCD_ENDPOINTS" ] && read -r -p "Enter Name [$DEF_ETCD_ENDPOINTS] " OPT_ETCD_ENDPOINTS
    [ -z "$OPT_ETCD_PREFIX" ] && read -r -p "Enter Name [$DEF_ETCD_PREFIX] " OPT_ETCD_PREFIX
    [ -z "$OPT_IFACE" ] && read -r -p "Enter Name [$DEF_IFACE] " OPT_IFACE
fi
[ -z "$OPT_ETCD_ENDPOINTS" ] && OPT_ETCD_ENDPOINTS=$DEF_ETCD_ENDPOINTS
[ -z "$OPT_ETCD_PREFIX" ] && OPT_ETCD_PREFIX=$DEF_ETCD_PREFIX
[ -z "$OPT_IFACE" ] && OPT_IFACE=$DEF_IFACE

########################################################################################################
# 安全安装

type sudo >/dev/null 2>&1 && SUDO="sudo"

$SUDO systemctl stop flannel 2>/dev/null
$SUDO systemctl disable flannel 2>/dev/null

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
# 安装 flannel

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR" >/dev/null || exit

$SUDO curl -sSL -o flannel.tar.gz https://github.com/flannel-io/flannel/releases/download/v${FLANNEL_VER}/flannel-v${FLANNEL_VER}-linux-${FLANNEL_ARCH}.tar.gz
$SUDO tar -xzf flannel.tar.gz

$SUDO mkdir -p $INSTALL_PATH
$SUDO install -m 755 flanneld mk-docker-opts.sh $INSTALL_PATH

popd >/dev/null || :
$SUDO rm -rf "$TEMP_DIR"

########################################################################################################
# 配置 flanneld

# flanneld 软件配置
$SUDO tee /etc/default/flanneld >/dev/null <<EOF
FLANNEL_ETCD_ENDPOINTS="$OPT_ETCD_ENDPOINTS"
FLANNEL_ETCD_PREFIX="$OPT_ETCD_PREFIX"
FLANNEL_IFACE="$OPT_IFACE"
EOF

# flanneld 服务配置
$SUDO mkdir -p $SEVICE_PATH
$SUDO tee $SEVICE_PATH/flanneld.service >/dev/null <<EOF
[Unit]
Description=flanneld - a simple and easy way to configure a layer 3 network fabric
Documentation=https://github.com/coreos/flannel
Documentation=man:flanneld
After=network.target
Wants=network-online.target

[Service]
Type=notify
# Environment=FLANNEL_ETCD_ENDPOINTS=$DEF_ETCD_ENDPOINTS
# Environment=FLANNEL_ETCD_PREFIX=$DEF_ETCD_PREFIX
EnvironmentFile=-/etc/default/flanneld
ExecStart=$INSTALL_PATH/flanneld \\
    --ip-masq \\
    --etcd-endpoints="\$FLANNEL_ETCD_ENDPOINTS" \\
    --etcd-prefix="\$FLANNEL_ETCD_PREFIX" \\
    --iface="\$FLANNEL_IFACE"
ExecStartPost=$INSTALL_PATH/mk-docker-opts.sh
Restart=on-abnormal
# RestartSec=10s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
$SUDO systemctl daemon-reload

# 启动 flanneld 服务，并设置为自启动
$SUDO systemctl enable flanneld
$SUDO systemctl start flanneld

########################################################################################################
# 生成卸载脚本

$SUDO tee /usr/local/bin/flannel-uninstall <<EOF >/dev/null
#!/usr/bin/env bash
set -x
type sudo >/dev/null 2>&1 && SUDO="sudo"

# 停止并禁用服务
\$SUDO systemctl stop flanneld 2>/dev/null
\$SUDO systemctl disable flanneld 2>/dev/null

# 删除服务
\$SUDO rm -f $SEVICE_PATH/flanneld.service
# 删除服务配置
\$SUDO rm -f /etc/default/flanneld
# 删除执行文件
\$SUDO rm -r $INSTALL_PATH/flanneld $INSTALL_PATH/mk-docker-opts.sh

if [ "\$1" = "-a" ] || [ "\$1" = "--all" ]; then
    # 清理配置
    # \$SUDO rm -rf /etc/flannel
    # 清理数据文件
    # \$SUDO rm -rf /var/lib/flannel
fi

# 删除脚本
\$SUDO rm -f /usr/local/bin/flannel-uninstall
EOF
$SUDO chmod +x /usr/local/bin/flannel-uninstall
