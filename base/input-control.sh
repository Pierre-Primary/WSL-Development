#! /bin/sh

_OLD_STTY=$(stty -g)
_ESC=$(printf "\033")
stty -echo
while true; do
    stty -icanon min 1 time 0
    _KEY="$(dd bs=1 count=1 2>/dev/null)"
    case $_KEY in
    "$_ESC")
        stty -icanon min 0 time 0
        _KEY="$(dd 2>/dev/null)"
        case $_KEY in
        "[A") echo "Up" ;;
        "[B") echo "Down" ;;
        "[C") echo "Right" ;;
        "[D") echo "Left" ;;
        "") echo "Esc" && break ;;
        *) continue ;;
        esac
        ;;
    " ") echo "Space" ;;
    "") echo "Enter" ;;
    q | Q) echo "Esc" && break ;;
    *) continue ;;
    esac
    [ "$1" != "--loop" ] && break
done
stty "$_OLD_STTY"
