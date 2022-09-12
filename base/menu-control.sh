#! /bin/sh
set -e

_S_PATH=$(
    cd "$(dirname "$0")"
    pwd
)

alias input-control=$_S_PATH/input-control.sh

print_opts() {
    _STX=$1 && shift
    _SHOW_NUMBER=$1 && shift
    _IDX=0
    for _OPT; do
        printf "\033[2K"
        [ "$_SHOW_NUMBER" -eq 1 ] && printf "%d) " $((_IDX + 1))
        [ "${_IDX}" -eq "${_STX}" ] && printf "\033[07m"
        printf "%s" "$_OPT"
        printf "\033[0m\n"
        _IDX=$((_IDX + 1))
    done
}

_STX=0
_SHOW_NUMBER=0

eval set -- "$(getopt -o t:i:n -l title:,index: -- "$@")"

while [ $# -gt 0 ]; do
    case $1 in
    -t | --title) _TITLE=$2 && shift ;;
    -i | --index) _STX=$2 && shift ;;
    -n) _SHOW_NUMBER=1 ;;
    --) shift && break ;;
    esac
    shift
done

[ $# -eq 0 ] && exit

[ -n "$_TITLE" ] && echo "$_TITLE"
if true; then
    trap 'printf "\033[?25h"' EXIT
    printf "\033[?25l"
    while true; do
        _STX=$(((_STX + $#) % $#))
        print_opts "$_STX" "$_SHOW_NUMBER" "$@"
        case $(input-control) in
        Up) _STX=$((_STX - 1)) ;;
        Down) _STX=$((_STX + 1)) ;;
        Enter) break ;;
        Esc) exit 0 ;;
        esac
        printf '\033[%dA' $#
    done
else
    print_opts "-1" "$_SHOW_NUMBER" "$@"
    printf "请选择:"
    read -r _STX
fi
exit $((_STX + 1))

# echo "1xxxxxxxxxxxxxxxxxxxxxxxxxxx"
# echo "2xxxxxxxxxxxxxxxxxxxxxxxxxxx"
# echo "3xxxxxxxxxxxxxxxxxxxxxxxxxxx"
# echo "4xxxxxxxxxxxxxxxxxxxxxxxxxxx"
# echo "5xxxxxxxxxxxxxxxxxxxxxxxxxxx"
# echo "6xxxxxxxxxxxxxxxxxxxxxxxxxxx"

# printf "\033[5A"
# printf "\033[K"
# printf "\033[L"
# printf "\033[2L"
# printf "\033[J"
# printf "\033[2J"
# printf "\033[6n"
