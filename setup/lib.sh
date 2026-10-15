#!/usr/bin/env bash

# Shared helpers. This file is sourced by the setup scripts.

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

note() {
    printf '%s\n' "$*"
}

repo_root() {
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
}

linux_target() {
    local machine
    machine=$(uname -m)
    case "$machine" in
        x86_64|amd64)
            printf '%s\n' x86_64-unknown-linux-gnu
            ;;
        aarch64|arm64)
            printf '%s\n' aarch64-unknown-linux-gnu
            ;;
        *)
            die "unsupported architecture '$machine'; expected x86_64 or aarch64"
            ;;
    esac
}

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        die "sha256sum or shasum is required to verify artifacts"
    fi
}

verify_recorded_sha256() {
    local file=$1
    local sums=$2
    local rel expected actual

    [ -f "$sums" ] || die "checksum file not found: $sums"
    rel=${file#"$(dirname -- "$sums")"/}
    expected=$(awk -v wanted="$rel" '$2 == wanted || $2 == "*" wanted {print $1; exit}' "$sums")
    [ -n "$expected" ] || die "no SHA-256 entry for '$rel' in $sums"
    actual=$(sha256_file "$file")
    [ "$actual" = "$expected" ] || die "SHA-256 mismatch for $file"
}

ensure_path_line() {
    local bashrc=$1
    local line='export PATH="$HOME/.local/bin:$PATH"'

    touch "$bashrc"
    if ! grep -Fqx "$line" "$bashrc"; then
        printf '\n%s\n' "$line" >> "$bashrc"
        note "Added ~/.local/bin to PATH in $bashrc"
    else
        note "$bashrc already contains the PATH entry"
    fi
}

