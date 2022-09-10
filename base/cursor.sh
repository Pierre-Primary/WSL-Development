# shellcheck shell=bash

if [ -z "$_SELECT_SHELL" ]; then
    export _SELECT_SHELL=1
    if hash bash 2>/dev/null; then
        exec /usr/bin/env bash "$0" "$@"
    elif hash ash 2>/dev/null; then
        exec /usr/bin/env ash "$0" "$@"
    else
        exit 1
    fi
    exit
fi
export _SELECT_SHELL=0
set -e

# SHELL_TYPE=$(ps -eo pid,comm | awk '$1 == '$$' { print $2 }')
# read -rsdR -p $'\E[6n' POINTS # bash

POINTS=""
stty -echo
printf "\033[6n"
while true; do
    read -rn1 _CHAR 2>/dev/null >&2
    [ -z "$_CHAR" ] || [ "$_CHAR" = "R" ] && break
    POINTS="$POINTS""$_CHAR"
done
stty echo

echo "${POINTS#*[}"
