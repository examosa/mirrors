#!/usr/bin/env bash

function doHelp() {
    echo "Usage: $0 [OPTION] COMMAND"
    echo
    echo "Options"
    echo
    echo "  -h, --help   Print this help"
    echo
    echo "Commands"
    echo
    echo "  help         Print this help"
    echo
    echo "  list         List all available test cases"
    echo
    echo "  run CASE     Run specified test case"
    echo
    echo "  run-all      Run all test cases"
}

function doList() {
    for testCase in @out@/bin/nmt-case-* ; do
        local name
        name=$(basename "$testCase")
        echo "${name#nmt-case-}"
    done
}

case $1 in
    -h|--help|help)
        doHelp
        ;;
    list)
        doList
        ;;
    run)
        doRun
        ;;
    run-all)
        doRunAll
        ;;
    *)
        doHelp
        ;;
esac
