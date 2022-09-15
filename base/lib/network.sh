# shellcheck shell=sh

GetDefaultIP() {
    ip addr | awk '/inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2); exit }'
}
