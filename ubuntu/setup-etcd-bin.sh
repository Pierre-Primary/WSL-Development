#!/usr/bin/env bash
set -x

# 配置安装版本
ETCD_VER=3.4.20
ETCD_ARCH=amd64

########################################################################################################
# 安全安装

type sudo >/dev/null 2>&1 && SUDO="sudo"

$SUDO systemctl stop etcd 2>/dev/null
$SUDO systemctl disable etcd 2>/dev/null

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

$SUDO mkdir -p $SEVICE_PATH

$SUDO tee /etc/etcd/conf.yml >/dev/null <<EOF
EOF

$SUDO tee /etc/default/etcd >/dev/null <<EOF
# ETCD_NAME="default"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2381"
EOF

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
$SUDO chmod u+x /usr/local/bin/etcd-uninstall
