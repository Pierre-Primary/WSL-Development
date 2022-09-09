#!/usr/bin/env sh
set -ex

# 安装并启动 openrc
if [ "$1" != "--enter" ]; then
    ./setup-openrc.sh
    /etc/wsl-init/enter "$0 --enter"
    exit
fi

cd "$(dirname "$0")"

# 查看配置是否生效
# SELECT  @@key_buffer_size  / (1024 * 1024) ;
# SELECT  @@query_cache_size  / (1024 * 1024) ;
# SELECT  @@query_cache_limit / (1024 * 1024) ;
# SELECT  @@innodb_buffer_pool_size  / (1024 * 1024) ;
# SELECT  @@innodb_log_buffer_size  / (1024 * 1024) ;
# SELECT  @@max_connections ;
# SELECT  @@read_buffer_size  / 1024 ;
# SELECT  @@read_rnd_buffer_size  / 1024 ;
# SELECT  @@sort_buffer_size  / 1024  ;
# SELECT  @@join_buffer_size  / 1024  ;
# SELECT  @@thread_stack  / 1024  ;
# SELECT  @@binlog_cache_size  / 1024  ;
# SELECT  @@tmp_table_size  / 1024  ;

# 安装服务
install_service() {

    type /usr/bin/mariadbd >/dev/null && return

    # 安装服务
    apk add mariadb

    # 初始化
    /etc/init.d/mariadb setup

    # 内存限制，小内存机器专用
    cat <<EOF | tee /etc/my.cnf.d/limit_mem.cnf
[mysqld]
performance_schema = off
key_buffer_size = 16M
query_cache_size = 1M
query-cache-limit = 1M
innodb_buffer_pool_size = 16M
innodb_log_buffer_size = 4M
max_connections = 50
read_buffer_size = 64K
read_rnd_buffer_size = 128K
sort_buffer_size = 512K
join_buffer_size = 128K
# thread_stack = 196K
# binlog_cache_size = 16K
tmp_table_size = 4M
EOF
    # 启动
    rc-update add mariadb default
    rc-service mariadb start
}

# 安装客户端
install_cli() {
    apk add mariadb-client
}

install_service
install_cli
