#!/bin/bash
[ -z "${_source_mark_of_common:+dummy}" ] || return 0
_source_mark_of_common=true

set -eEuo pipefail

################################################################################
# constants
################################################################################

# NOTE: $'foo' is the escape sequence syntax of bash
readonly nl=$'\n'        # new line
readonly ec=$'\033'      # escape char
readonly eend=$'\033[0m' # escape end

################################################################################
# trap error setting
################################################################################

# https://stackoverflow.com/questions/6928946/mysterious-lineno-in-bash-trap-err
# https://stackoverflow.com/questions/64786/error-handling-in-bash
# https://stackoverflow.com/questions/24398691/how-to-get-the-real-line-number-of-a-failing-bash-command
# https://unix.stackexchange.com/questions/39623/trap-err-and-echoing-the-error-line
# https://unix.stackexchange.com/questions/462156/how-do-i-find-the-line-number-in-bash-when-an-error-occured
# https://unix.stackexchange.com/questions/365113/how-to-avoid-error-message-during-the-execution-of-a-bash-script
# https://shapeshed.com/unix-exit-codes/#how-to-suppress-exit-statuses
# https://stackoverflow.com/questions/30078281/raise-error-in-a-bash-script/50265513#50265513
__error_trap_handler_() {
    local file_line_info="$1"
    local code="$2"
    local commands="$3"
    echo "Trap error! Exit status: $code${nl}File/(near) line info:$nl  $file_line_info${nl}Error code line:$nl  $commands" >&2
}
trap '__error_trap_handler_ "${BASH_SOURCE[*]} / $LINENO ${BASH_LINENO[*]}" "$?" "$BASH_COMMAND"' ERR

################################################################################
# util functions
################################################################################

colorEcho() {
    local color=$1
    shift

    # if stdout is the console, turn on color output.
    [ -t 1 ] && echo "${ec}[1;${color}m$*${eend}" || echo "$*"
}

redEcho() {
    colorEcho 31 "$@"
}

yellowEcho() {
    colorEcho 33 "$@"
}

blueEcho() {
    colorEcho 36 "$@"
}

headInfo() {
    colorEcho "0;34;46" ================================================================================
    echo "$*"
    colorEcho "0;34;46" ================================================================================
    echo
}

# How to compare a program's version in a shell script?
#   https://unix.stackexchange.com/questions/285924
versionGreatEqThan() {
    (($# == 2)) || die "${FUNCNAME[0]} need only 2 arguments, actual arguments: $*"

    local ver=$1
    local destVer=$2

    [ "$ver" = "$destVer" ] && return 1

    [ "$(printf '%s\n' "$ver" "$destVer" | sort -V | head -n1)" = "$destVer" ]
}

logAndRun() {
    blueEcho "Run under work directory $PWD :$nl$*"
    time "$@"
}

die() {
    redEcho "Error: $*" 1>&2
    exit 1
}

# How to determine function name from inside a function
#   https://stackoverflow.com/questions/1835943
# Bash Shell: Check If A Function Exists Or Not (Find Out If a Function Is Defined Or Not)
#   https://www.cyberciti.biz/faq/bash-shell-scripting-find-out-if-function-definedornot/
checkNecessityForCallerFunction() {
    if ((${#FUNCNAME[@]} < 3)); then
        return 0
    fi

    local checkNecessityFunctionName="${FUNCNAME[1]}_Necessity"
    if declare -F "$checkNecessityFunctionName" &>/dev/null; then
        "$checkNecessityFunctionName"
    fi
}
