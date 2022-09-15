#! /bin/sh

_ESC=$(printf '\033')

_OLD_STTY=$(stty -g)
stty -echo
while true; do
    printf '\r'
    stty raw -icanon min 1 time 0
    _KEY_FIRST="$(exec dd bs=1 count=1 2>/dev/null)"
    case $_KEY_FIRST in
    "$_ESC") # ASCII Escape
        stty raw -icanon min 0 time 0
        _KEY_LAST="$(exec dd 2>/dev/null)"
        case $(echo "$_KEY_LAST" | grep -o ';\d') in
        "")
            # {key}
            case $_KEY_LAST in
            "") echo "Esc" && break ;;

            "[A") echo "Up" ;;
            "[B") echo "Down" ;;
            "[C") echo "Right" ;;
            "[D") echo "Left" ;;

            "OP") echo "F1" ;;
            "OQ") echo "F2" ;;
            "OR") echo "F3" ;;
            "OS") echo "F4" ;;
            "[15~") echo "F5" ;;
            "[17~") echo "F6" ;;
            "[18~") echo "F7" ;;
            "[19~") echo "F8" ;;
            "[20~") echo "F9" ;;
            "[21~") echo "F10" ;;
            "[23~") echo "F11" ;;
            "[24~") echo "F12" ;;

            "[F") echo "End" ;;
            "[H") echo "Home" ;;
            "[2~") echo "Ins" ;;  # Insert
            "[3~") echo "Del" ;;  # Delete
            "[5~") echo "PgUp" ;; # Page Up
            "[6~") echo "PgDn" ;; # Page Down

            *) continue ;;
            esac
            ;;
        ";2")
            # Shift+{key}
            case $_KEY_LAST in
            "[1;2A") echo "Shift+Up" ;;
            "[1;2B") echo "Shift+Down" ;;
            "[1;2C") echo "Shift+Right" ;;
            "[1;2D") echo "Shift+Left" ;;

            "[1;2P") echo "Shift+F1" ;;
            "[1;2Q") echo "Shift+F2" ;;
            "[1;2R") echo "Shift+F3" ;;
            "[1;2S") echo "Shift+F4" ;;
            "[15;2~") echo "Shift+F5" ;;
            "[17;2~") echo "Shift+F6" ;;
            "[18;2~") echo "Shift+F7" ;;
            "[19;2~") echo "Shift+F8" ;;
            "[20;2~") echo "Shift+F9" ;;
            "[21;2~") echo "Shift+F10" ;;
            "[23;2~") echo "Shift+F11" ;;
            "[24;2~") echo "Shift+F12" ;;

            "[1;2F") echo "Shift+End" ;;
            "[1;2H") echo "Shift+Home" ;;
            "[2;2~") echo "Shift+Ins" ;;
            "[3;2~") echo "Shift+Del" ;;
            "[5;2~") echo "Shift+PgUp" ;;
            "[6;2~") echo "Shift+PgDn" ;;

            *) continue ;;
            esac
            ;;
        ";3")
            # Alt+{key}
            case $_KEY_LAST in
            "[1;3A") echo "Alt+Up" ;;
            "[1;3B") echo "Alt+Down" ;;
            "[1;3C") echo "Alt+Right" ;;
            "[1;3D") echo "Alt+Left" ;;

            "[1;3P") echo "Alt+F1" ;;
            "[1;3Q") echo "Alt+F2" ;;
            "[1;3R") echo "Alt+F3" ;;
            "[1;3S") echo "Alt+F4" ;;
            "[15;3~") echo "Alt+F5" ;;
            "[17;3~") echo "Alt+F6" ;;
            "[18;3~") echo "Alt+F7" ;;
            "[19;3~") echo "Alt+F8" ;;
            "[20;3~") echo "Alt+F9" ;;
            "[21;3~") echo "Alt+F10" ;;
            "[23;3~") echo "Alt+F11" ;;
            "[24;3~") echo "Alt+F12" ;;

            "[1;3F") echo "Alt+End" ;;
            "[1;3H") echo "Alt+Home" ;;
            "[2;3~") echo "Alt+Ins" ;;
            "[3;3~") echo "Alt+Del" ;;
            "[5;3~") echo "Alt+PgUp" ;;
            "[6;3~") echo "Alt+PgDn" ;;

            *) continue ;;
            esac
            ;;
        ";4")
            # Alt+Shift+{key}
            case $_KEY_LAST in
            "[1;4A") echo "Alt+Shift+Up" ;;
            "[1;4B") echo "Alt+Shift+Down" ;;
            "[1;4C") echo "Alt+Shift+Right" ;;
            "[1;4D") echo "Alt+Shift+Left" ;;

            "[1;4P") echo "Alt+Shift+F1" ;;
            "[1;4Q") echo "Alt+Shift+F2" ;;
            "[1;4R") echo "Alt+Shift+F3" ;;
            "[1;4S") echo "Alt+Shift+F4" ;;
            "[15;4~") echo "Alt+Shift+F5" ;;
            "[17;4~") echo "Alt+Shift+F6" ;;
            "[18;4~") echo "Alt+Shift+F7" ;;
            "[19;4~") echo "Alt+Shift+F8" ;;
            "[20;4~") echo "Alt+Shift+F9" ;;
            "[21;4~") echo "Alt+Shift+F10" ;;
            "[23;4~") echo "Alt+Shift+F11" ;;
            "[24;4~") echo "Alt+Shift+F12" ;;

            "[1;4F") echo "Alt+Shift+End" ;;
            "[1;4H") echo "Alt+Shift+Home" ;;
            "[2;4~") echo "Alt+Shift+Ins" ;;
            "[3;4~") echo "Alt+Shift+Del" ;;
            "[5;4~") echo "Alt+Shift+PgUp" ;;
            "[6;4~") echo "Alt+Shift+PgDn" ;;

            *) continue ;;
            esac
            ;;
        ";5")
            # Ctrl+{key}
            case $_KEY_LAST in
            "[1;5A") echo "Ctrl+Up" ;;
            "[1;5B") echo "Ctrl+Down" ;;
            "[1;5C") echo "Ctrl+Right" ;;
            "[1;5D") echo "Ctrl+Left" ;;

            "[1;5P") echo "Ctrl+F1" ;;
            "[1;5Q") echo "Ctrl+F2" ;;
            "[1;5R") echo "Ctrl+F3" ;;
            "[1;5S") echo "Ctrl+F4" ;;
            "[15;5~") echo "Ctrl+F5" ;;
            "[17;5~") echo "Ctrl+F6" ;;
            "[18;5~") echo "Ctrl+F7" ;;
            "[19;5~") echo "Ctrl+F8" ;;
            "[20;5~") echo "Ctrl+F9" ;;
            "[21;5~") echo "Ctrl+F10" ;;
            "[23;5~") echo "Ctrl+F11" ;;
            "[24;5~") echo "Ctrl+F12" ;;

            "[1;5F") echo "Ctrl+End" ;;
            "[1;5H") echo "Ctrl+Home" ;;
            "[2;5~") echo "Ctrl+Ins" ;;
            "[3;5~") echo "Ctrl+Del" ;;
            "[5;5~") echo "Ctrl+PgUp" ;;
            "[6;5~") echo "Ctrl+PgDn" ;;

            *) continue ;;
            esac
            ;;
        ";6")
            # Ctrl+Shift+{key}
            case $_KEY_LAST in
            "[1;6A") echo "Ctrl+Shift+Up" ;;
            "[1;6B") echo "Ctrl+Shift+Down" ;;
            "[1;6C") echo "Ctrl+Shift+Right" ;;
            "[1;6D") echo "Ctrl+Shift+Left" ;;

            "[1;6P") echo "Ctrl+Shift+F1" ;;
            "[1;6Q") echo "Ctrl+Shift+F2" ;;
            "[1;6R") echo "Ctrl+Shift+F3" ;;
            "[1;6S") echo "Ctrl+Shift+F4" ;;
            "[15;6~") echo "Ctrl+Shift+F5" ;;
            "[17;6~") echo "Ctrl+Shift+F6" ;;
            "[18;6~") echo "Ctrl+Shift+F7" ;;
            "[19;6~") echo "Ctrl+Shift+F8" ;;
            "[20;6~") echo "Ctrl+Shift+F9" ;;
            "[21;6~") echo "Ctrl+Shift+F10" ;;
            "[23;6~") echo "Ctrl+Shift+F11" ;;
            "[24;6~") echo "Ctrl+Shift+F12" ;;

            "[1;6F") echo "Ctrl+Shift+End" ;;
            "[1;6H") echo "Ctrl+Shift+Home" ;;
            "[2;6~") echo "Ctrl+Shift+Ins" ;;
            "[3;6~") echo "Ctrl+Shift+Del" ;;
            "[5;6~") echo "Ctrl+Shift+PgUp" ;;
            "[6;6~") echo "Ctrl+Shift+PgDn" ;;

            *) continue ;;
            esac
            ;;
        ";7")
            # Ctrl+Alt+{key}
            case $_KEY_LAST in
            "[1;7A") echo "Ctrl+Alt+Up" ;;
            "[1;7B") echo "Ctrl+Alt+Down" ;;
            "[1;7C") echo "Ctrl+Alt+Right" ;;
            "[1;7D") echo "Ctrl+Alt+Left" ;;

            "[1;7P") echo "Ctrl+Alt+F1" ;;
            "[1;7Q") echo "Ctrl+Alt+F2" ;;
            "[1;7R") echo "Ctrl+Alt+F3" ;;
            "[1;7S") echo "Ctrl+Alt+F4" ;;
            "[15;7~") echo "Ctrl+Alt+F5" ;;
            "[17;7~") echo "Ctrl+Alt+F6" ;;
            "[18;7~") echo "Ctrl+Alt+F7" ;;
            "[19;7~") echo "Ctrl+Alt+F8" ;;
            "[20;7~") echo "Ctrl+Alt+F9" ;;
            "[21;7~") echo "Ctrl+Alt+F10" ;;
            "[23;7~") echo "Ctrl+Alt+F11" ;;
            "[24;7~") echo "Ctrl+Alt+F12" ;;

            "[1;7F") echo "Ctrl+Alt+End" ;;
            "[1;7H") echo "Ctrl+Alt+Home" ;;
            "[2;7~") echo "Ctrl+Alt+Ins" ;;
            "[3;7~") echo "Ctrl+Alt+Del" ;;
            "[5;7~") echo "Ctrl+Alt+PgUp" ;;
            "[6;7~") echo "Ctrl+Alt+PgDn" ;;

            *) continue ;;
            esac
            ;;
        ";8")
            # Ctrl+Alt+Shift+{key}
            case $_KEY_LAST in
            "[1;8A") echo "Ctrl+Alt+Shift+Up" ;;
            "[1;8B") echo "Ctrl+Alt+Shift+Down" ;;
            "[1;8C") echo "Ctrl+Alt+Shift+Right" ;;
            "[1;8D") echo "Ctrl+Alt+Shift+Left" ;;

            "[1;8P") echo "Ctrl+Alt+Shift+F1" ;;
            "[1;8Q") echo "Ctrl+Alt+Shift+F2" ;;
            "[1;8R") echo "Ctrl+Alt+Shift+F3" ;;
            "[1;8S") echo "Ctrl+Alt+Shift+F4" ;;
            "[15;8~") echo "Ctrl+Alt+Shift+F5" ;;
            "[17;8~") echo "Ctrl+Alt+Shift+F6" ;;
            "[18;8~") echo "Ctrl+Alt+Shift+F7" ;;
            "[19;8~") echo "Ctrl+Alt+Shift+F8" ;;
            "[20;8~") echo "Ctrl+Alt+Shift+F9" ;;
            "[21;8~") echo "Ctrl+Alt+Shift+F10" ;;
            "[23;8~") echo "Ctrl+Alt+Shift+F11" ;;
            "[24;8~") echo "Ctrl+Alt+Shift+F12" ;;

            "[1;8F") echo "Ctrl+Alt+Shift+End" ;;
            "[1;8H") echo "Ctrl+Alt+Shift+Home" ;;
            "[2;8~") echo "Ctrl+Alt+Shift+Ins" ;;
            "[3;8~") echo "Ctrl+Alt+Shift+Del" ;;
            "[5;8~") echo "Ctrl+Alt+Shift+PgUp" ;;
            "[6;8~") echo "Ctrl+Alt+Shift+PgDn" ;;

            *) continue ;;
            esac
            ;;
        *) continue ;;
        esac
        ;;
    *) # ASCII
        _KEY_NAME="$(printf "%s" "$_KEY_FIRST" | od -A n -t a)"
        _KEY_NAME=$(echo "$_KEY_NAME" | sed -E 's/^[ \t]+//g' | sed -E 's/[ \t]+$//g')
        if [ "$_KEY_NAME" = "$_KEY_FIRST" ]; then
            echo "$_KEY_NAME"
        else
            echo "$_KEY_NAME" | tr '[:lower:]' '[:upper:]'
        fi
        ;;
    esac
    [ "$1" != "--loop" ] && break
done
stty "$_OLD_STTY"
