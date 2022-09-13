#!/usr/bin/env bash
set -x

# 配置安装版本
DOCKER_VER=20.10.18
DOCKER_ARCH=x86_64

########################################################################################################
# 安全安装

type sudo >/dev/null 2>&1 && SUDO="sudo"

$SUDO systemctl stop docker.service docker.socket containerd.service 2>/dev/null
$SUDO systemctl disable docker.service docker.socket containerd.service 2>/dev/null

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
# 安装 docker, 包含 ( dockerd, docker-cli, containerd, ctr, runc 等 )

PKG_URL=https://mirrors.ustc.edu.cn/docker-ce/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VER}.tgz

TEMP_DIR=$(mktemp -d)

curl -sL "$PKG_URL" |
    $SUDO tar -xzv -C "$TEMP_DIR" --strip-components=1 --no-same-owner

$SUDO mkdir -p $INSTALL_PATH
$SUDO install -m 755 "${TEMP_DIR}"/* $INSTALL_PATH

DOCKER_FILES=$($SUDO find "$TEMP_DIR" -type f | sed -E "s|^$TEMP_DIR|$INSTALL_PATH|g" | tr "\n" " ")
$SUDO rm -rf "$TEMP_DIR"

########################################################################################################
# 配置 containerd

# containerd 软件配置
$SUDO mkdir -p /etc/containerd
containerd config default | $SUDO tee /etc/containerd/config.toml >/dev/null

$SUDO mkdir -p $SEVICE_PATH

# containerd 服务配置
# https://github.com/containerd/containerd/blob/main/containerd.service
$SUDO tee $SEVICE_PATH/containerd.service >/dev/null <<EOF
[Unit]
Description=Containerd Container Runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
# Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=$INSTALL_PATH/containerd --address=/run/containerd/containerd.sock

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity

TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
$SUDO systemctl daemon-reload

# 启动 containerd 服务，并设置为自启动
$SUDO systemctl enable containerd
$SUDO systemctl start containerd

########################################################################################################
# 配置 docker

# 创建 docker 用户组
$SUDO groupadd -f docker

$SUDO mkdir -p $SEVICE_PATH

# docker 服务配置
$SUDO tee $SEVICE_PATH/docker.socket >/dev/null <<EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

$SUDO tee $SEVICE_PATH/docker.service >/dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket containerd.service

[Service]
Type=notify
ExecStart=$INSTALL_PATH/dockerd -H fd:// -H tcp://0.0.0.0:2375 --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

StartLimitBurst=3

StartLimitInterval=60s

LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

TasksMax=infinity

Delegate=yes

KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF
$SUDO systemctl daemon-reload

# 启动 docker 服务，并设置为自启动
$SUDO systemctl enable docker.service docker.socket
$SUDO systemctl start docker.service docker.socket

########################################################################################################
# 生成卸载脚本

$SUDO tee /usr/local/bin/docker-uninstall <<EOF >/dev/null
#!/usr/bin/env bash
set -x
type sudo >/dev/null 2>&1 && SUDO="sudo"

# 停止并禁用服务
\$SUDO systemctl stop docker.service docker.socket containerd.service 2>/dev/null
\$SUDO systemctl disable docker.service docker.socket containerd.service 2>/dev/null

# 删除服务
\$SUDO rm -f $SEVICE_PATH/docker.service $SEVICE_PATH/docker.socket $SEVICE_PATH/containerd.service
# 删除服务配置
\$SUDO rm -f /etc/default/docker
# 删除执行文件
${DOCKER_FILES:+\$SUDO rm -f $DOCKER_FILES}

if [ "\$1" = "-a" ] || [ "\$1" = "--all" ]; then
    # 清理配置
    \$SUDO rm -rf /etc/docker /etc/containerd
    # 清理数据文件
    \$SUDO rm -rf /var/lib/docker /var/lib/containerd
    # 删除用户组
    \$SUDO groupdel docker 2>/dev/null
fi

# 删除脚本
\$SUDO rm -f /usr/local/bin/docker-uninstall
EOF
$SUDO chmod u+x /usr/local/bin/docker-uninstall

########################################################################################################

# find / -path /mnt -prune -o -path /proc -prune -o -path /sys -prune -o -name docker 2>/dev/null

# sudo mount -t vboxsf share /mnt/g
