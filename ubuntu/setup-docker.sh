#!/usr/bin/env bash
set -x

type sudo >/dev/null 2>&1 && SUDO="sudo"

$SUDO apt update

# 卸载旧版
$SUDO apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null

# 安装工具
$SUDO apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

########################################################################################################

# 配置 Docker 软件源密钥
$SUDO mkdir -p /etc/apt/keyrings
$SUDO rm -f /etc/apt/keyrings/docker.gpg
curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg |
    $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 配置 Docker 软件源
$SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable
EOF
$SUDO apt update

########################################################################################################

# 安装 Docker
$SUDO apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin

# 配置 Docker
$SUDO sed -ri '/^ExecStart=/c ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375 --containerd=/run/containerd/containerd.sock' /lib/systemd/system/docker.service
$SUDO systemctl daemon-reload

# 重启 docker 服务
$SUDO systemctl restart docker

########################################################################################################
# 生成卸载脚本

$SUDO tee /usr/local/bin/docker-uninstall <<EOF >/dev/null
#!/usr/bin/env bash
set -x
type sudo >/dev/null 2>&1 && SUDO="sudo"

# 卸载程序
\$SUDO apt autoremove -y --purge docker-ce docker-ce-cli containerd.io docker-compose-plugin

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
