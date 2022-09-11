# shellcheck shell=sh

poxis_input() {
    eval set -- "$(exec getopt -o n:t:d:p:s -- "$@")"
    while [ $# -gt 0 ]; do
        case $1 in
        -n) _OPT_NCHARS="$(echo "$2" | bc)" && shift ;;
        -t) _OPT_TIMEOUT="$(echo "$2*10" | bc)" && _OPT_TIMEOUT=${_OPT_TIMEOUT%%.*} && shift ;;
        -d) _OPT_DELIM=$2 && shift ;;
        -p) _OPT_PROMPT=$2 && shift ;;
        -s) _OPT_DISECHO=1 ;;
        --) shift && break ;;
        esac
        shift
    done

    _OLD_STTY=$(stty -g)

    stty -icanon
    [ -n "$_OPT_DISECHO" ] &&
        stty -echo
    [ -n "$_OPT_TIMEOUT" ] &&
        stty -icanon min 0 time "$_OPT_TIMEOUT"
    [ -n "$_OPT_PROMPT" ] &&
        printf "%s" "$_OPT_PROMPT"

    _IFS=$IFS
    _START_T=$(($(date +%s%N) / 100000000))
    _CANCEL=0
    while true; do
        [ -n "$_OPT_NCHARS" ] && [ ${#_RAW} -ge "$_OPT_NCHARS" ] && break
        _CHAR="$(exec dd bs=1 count=1 2>/dev/null)"
        if [ -n "$_OPT_TIMEOUT" ]; then
            _NOW_T=$(($(date +%s%N) / 100000000))
            if [ "$((_NOW_T - _START_T))" -gt "$_OPT_TIMEOUT" ]; then
                _CANCEL=1
                break
            fi
        fi
        [ -z "$_CHAR" ] && break
        [ -n "$_OPT_DELIM" ] && [ "$_OPT_DELIM" = "$_CHAR" ] && break
        if [ $# -gt 1 ]; then
            _POS=${_IFS%%"$_CHAR"*}
            if [ ${#_POS} -lt ${#_IFS} ]; then
                _KVS="${_KVS} ${1}=\"${_WORD}\""
                unset _WORD _CHAR
                shift
            fi
        fi
        _RAW="${_RAW}${_CHAR}"
        [ "$_CHAR" = '"' ] && _CHAR='\"'
        _WORD="${_WORD}${_CHAR}"
    done
    # stty -icanon -echo min 0 time 0
    # dd bs=1 >/dev/null 2>&1
    stty "$_OLD_STTY"

    [ -z "$_CANCEL" ] && [ $# -ge 1 ] &&
        eval "${_KVS} ${1}=\"${_WORD}\""

    unset _OPT_NCHARS _OPT_TIMEOUT _OPT_DELIM _OPT_PROMPT _OPT_DISECHO
    unset _IFS _OLD_STTY _RAW _WORD _CHAR _POS _KVS
}

# stty -raw
# read hhh

# 源样子
# stty raw
# stty -raw

# Ctrl-W，Ctrl-D，Ctrl-H，Ctrl-X
# stty -icanon
# stty icanon

# timestamp() {
#     CURRENT=$(date "+%Y-%m-%d %H:%M:%S")
#     echo $(($(date -d "$CURRENT" +%s)))
# }

# current_timestamp() {
#     _MS=$(echo "$(date "+%N")/1000000" | bc)
#     echo $(($(timestamp) * 1000 + _MS))
# }
