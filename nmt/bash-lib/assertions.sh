#!/usr/bin/env bash

# Internal helper to produce an absolute file path. Specifically, the given
# argument is returned as-is if it is an absolute path (starts with '/').
# Otherwise it is returned with a "$TESTED/" prefix.
#
# Example:
#    _abs "foo/bar"  ⇒ "$TESTED/foo/bar"
#    _abs "/foo/bar" ⇒ "/foo/bar"
function _abs() {
    [[ $1 == /* ]] && echo "$1" || echo "$TESTED/$1"
}

# Normalizes Nix store paths of a given file. Specifically, this function
# creates a copy of a given file but with all contained Nix store paths
# normalized such that they begin with
#
#     /nix/store/00000000000000000000000000000000
#
# The path to the created file is echoed to standard output.
#
# Example:
#     normalizeStorePaths foo/bar.txt
#
function normalizeStorePaths() {
    local input output normalizedName
    input="$(_abs "$1")"
    normalizedName="${input##*/}"
    mkdir -p "${out:?}/normalized"
    output="${out:?}/normalized/$normalizedName"
    sed -E "s!$NIX_STORE"'/[a-z0-9]{32}((-[a-zA-Z][a-zA-Z0-9+._?=]*)*)(-[a-zA-Z0-9+._?=-]*)?!/nix/store/00000000000000000000000000000000\1!g' \
        < "$input" > "$output"
    echo "$output"
}

# Always failing assertion with a message.
#
# Example:
#     fail "It should have been but it wasn't to be"
function fail() {
    echo "$1"
    exit 1
}

# Asserts the non-existence of a file system path.
#
# Example:
#     assertPathNotExists foo/bar.txt
#
function assertPathNotExists() {
    if [[ -e $(_abs "$1") ]]; then
        fail "Expected $1 to be missing but it exists."
    fi
}

# Asserts the existence of a file.
#
# Example:
#     assertFileExists foo/bar.txt
#
function assertFileExists() {
    if [[ ! -f $(_abs "$1") ]]; then
        fail "Expected $1 to exist but it was not found."
    fi
}

function assertFileIsExecutable() {
    if [[ ! -x $(_abs "$1") ]]; then
        fail "Expected $1 to be executable but it was not."
    fi
}

function assertFileIsNotExecutable() {
    if [[ -x $(_abs "$1") ]]; then
        fail "Expected $1 to not be executable but it was."
    fi
}

function sourceFile() {
    assertFileExists "$1"
    # shellcheck disable=SC1090
    source "$(_abs "$1")"
}

# Asserts that the given file contains the given line of text.
#
# Example:
#     assertFileContains foo/bar.txt "this line exists"
#
function assertFileContains() {
    if ! grep -qF "$2" "$(_abs "$1")"; then
        fail "Expected $1 to contain $2 but it did not."
    fi
}

# Asserts that the content of a file matches a given regular
# expression.
#
# Example:
#     assertFileRegex foo/bar.txt "^this line exists$"
#
function assertFileRegex() {
    if ! grep -q "$2" "$(_abs "$1")"; then
        fail "Expected $1 to match $2 but it did not."
    fi
}

# Asserts that the content of a file does not match a given regular
# expression.
#
# Example:
#     assertFileNotRegex foo/bar.txt "^this line is missing$"
#
function assertFileNotRegex() {
    if grep -q "$2" "$(_abs "$1")"; then
        fail "Expected $1 to not match $2 but it did."
    fi
}

# Asserts that the content of a file matches another file.
#
# Example:
#     assertFileCompare foo/bar.txt bar-expected.txt
function assertFileContent() {
    if ! cmp -s "$(_abs "$1")" "$2"; then
        fail "Expected $1 to be same as $2 but were different:
$(diff -du --label actual --label expected "$(_abs "$1")" "$2")"
    fi
}

# Asserts the existence of a symlink.
#
# Example:
#     assertLinkExists foo/bar
#
function assertLinkExists() {
    if [[ ! -L $(_abs "$1") ]]; then
        fail "Expected symlink $1 to exist but it was not found."
    fi
}

# Asserts whether a symlink points to the appropriate file.
#
# Example:
#     assertLinkPointsTo foo/bar /etc/foo
#
function assertLinkPointsTo() {
    assertLinkExists "$1"

    target="$(readlink "$(_abs "$1")")"

    # A symlink may point to a non-existing file so there is no need
    # to check if the path exists.
    if [[ "$target" != "$2" ]]; then
        fail "Symlink $1 was supposed to point to $2, but it actually points to $target."
    fi
}

# Asserts the existence of a directory.
#
# Example:
#     assertDirectoryExists foo/bar
#
function assertDirectoryExists() {
    if [[ ! -d $(_abs "$1") ]]; then
        fail "Expected directory $1 to exist but it was not found."
    fi
}

# Asserts that a directory exists but is empty.
#
# Example:
#     assertDirectoryEmpty foo/bar
#
function assertDirectoryEmpty() {
    assertDirectoryExists "$1"

    local content
    content="$(find "$(_abs "$1")" -mindepth 1 -maxdepth 1 -printf '%P\n')"

    if [[ $content ]]; then
        fail "Expected directory $1 to be empty but it contains
$content"
    fi
}

# Asserts that a directory exists and is not empty.
#
# Example:
#     assertDirectoryNotEmpty foo/bar
#
function assertDirectoryNotEmpty() {
    assertDirectoryExists "$1"

    if [[ ! $(find "$(_abs "$1")" -mindepth 1 -maxdepth 1) ]]; then
        fail "Expected directory $1 to be not empty but it was."
    fi
}
