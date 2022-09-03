#!/usr/bin/env bash
set -ex

# 依赖 setup-openrc.sh

apk add docker

rc-update add docker default

cat <<EOF | tee /etc/conf.d/docker
#DOCKER_LOGFILE="/var/log/docker.log"
#DOCKER_OUTFILE="/var/log/docker-out.log"
#DOCKER_ERRFILE="/var/log/docker-err.log"
#DOCKER_ULIMIT="-c unlimited -n 1048576 -u unlimited"
#DOCKER_RETRY="TERM/60/KILL/10"
DOCKERD_BINARY="/usr/bin/dockerd"
DOCKER_OPTS="-H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375"
EOF

service docker restart

# apk add docker-bash-completion
# apk add docker-compose-bash-completion
