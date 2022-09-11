#! /bin/sh

OLD_STTY=$(stty -g)
ESC=$(printf "\033")
stty -echo
while true; do
    stty -icanon min 1 time 0
    _CHAR="$(dd bs=1 count=1 2>/dev/null)"
    case $_CHAR in
    "${ESC}")
        stty -icanon min 0 time 1
        _CHAR="$(dd bs=1 count=2 2>/dev/null)"
        case $_CHAR in
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
stty "$OLD_STTY"
