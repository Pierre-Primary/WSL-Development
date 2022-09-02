#!/usr/bin/env bash
set -ex

apk add docker
rc-update add docker default
service docker start

# apk add docker-bash-completion
# apk add docker-compose-bash-completion
