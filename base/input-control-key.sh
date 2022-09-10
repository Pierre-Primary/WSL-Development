# shellcheck shell=bash
if [ "$1" = "--check" ]; then
    (hash bash 2>/dev/null || hash ash 2>/dev/null) && exit 0
    exit 1
elif [ -z "$_SELECT_SHELL" ]; then
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

ESC=$(printf "\033")
while true; do
    IFS='' read -rsn1 _KEY
    case $_KEY in
    "${ESC}")
        IFS='' read -rs -n2 -t0.001 _KEY >/dev/null 2>&1
        case $_KEY in
        "[A") echo "up" && break ;;
        "[B") echo "down" && break ;;
        "[C") echo "right" && break ;;
        "[D") echo "left" && break ;;
        "") echo "quit" && break ;;
        esac
        ;;
    " ") echo "select" && break ;;
    "") echo "enter" && break ;;
    q | Q) echo "quit" && break ;;
    esac
done
