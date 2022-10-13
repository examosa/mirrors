#!/usr/bin/env bash

# The check for terminal output and color support is heavily inspired
# by https://unix.stackexchange.com/a/10065.

function setupColors() {
    NORMAL_COLOR=""
    ERROR_COLOR=""
    WARN_COLOR=""
    NOTE_COLOR=""

    # Check if stdout is a terminal.
    if [[ -t 1 ]]; then
        # See if it supports colors.
        local ncolors
        ncolors=$(tput colors)

        if [[ -n "$ncolors" && "$ncolors" -ge 8 ]]; then
            NORMAL_COLOR="$(tput sgr0)"
            ERROR_COLOR="$(tput bold)$(tput setaf 1)"
            WARN_COLOR="$(tput setaf 3)"
            NOTE_COLOR="$(tput bold)$(tput setaf 6)"
        fi
    fi
}

setupColors

function errorEcho() {
    echo "${ERROR_COLOR}$*${NORMAL_COLOR}"
}

function warnEcho() {
    echo "${WARN_COLOR}$*${NORMAL_COLOR}"
}

function noteEcho() {
    echo "${NOTE_COLOR}$*${NORMAL_COLOR}"
}
