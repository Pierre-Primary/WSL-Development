#!/usr/bin/env bash
set -x

type sudo >/dev/null 2>&1 && SUDO="sudo"

$SUDO apt update

########################################################################################################

# 安装 Docker
$SUDO apt install -y etcd

$SUDO systemctl daemon-reload
$SUDO systemctl restart etcd

########################################################################################################
# 生成卸载脚本

$SUDO tee /usr/local/bin/etcd-uninstall <<EOF >/dev/null
#!/usr/bin/env bash
set -x
type sudo >/dev/null 2>&1 && SUDO="sudo"

\$SUDO apt autoremove -y --purge etcd

\$SUDO rm -f /usr/local/bin/etcd-uninstall
EOF
$SUDO chmod u+x /usr/local/bin/etcd-uninstall
