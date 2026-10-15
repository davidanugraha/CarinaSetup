#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=VERSIONS.env
source "$ROOT/VERSIONS.env"

section() {
    printf '\n== %s ==\n' "$1"
}

probe_url() {
    local label=$1
    local url=$2
    local result
    if ! command -v curl >/dev/null 2>&1; then
        printf '%-24s %s\n' "$label" 'UNKNOWN (curl not installed)'
        return
    fi
    if result=$(curl --location --head --silent --show-error \
        --connect-timeout 4 --max-time 10 \
        --output /dev/null --write-out '%{http_code}' \
        "$url" 2>&1); then
        printf '%-24s OK (%s)\n' "$label" "$result"
    else
        printf '%-24s FAIL (%s)\n' "$label" "$result"
    fi
}

section System
printf 'uname -m: %s\n' "$(uname -m)"
printf 'uname -sr: %s\n' "$(uname -sr)"
if command -v getconf >/dev/null 2>&1; then
    printf 'glibc: %s\n' "$(getconf GNU_LIBC_VERSION 2>/dev/null || printf 'not reported')"
else
    printf 'glibc: UNKNOWN (getconf not installed)\n'
fi
if command -v ldd >/dev/null 2>&1; then
    printf 'ldd: %s\n' "$(ldd --version 2>&1 | sed -n '1p')"
else
    printf 'ldd: not found\n'
fi

section Network
probe_url github.com https://github.com/
probe_url release-assets \
    "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz.sha256"
for proxy_name in HTTPS_PROXY https_proxy HTTP_PROXY http_proxy; do
    if [ -n "${!proxy_name:-}" ]; then
        printf '%s is set (value hidden)\n' "$proxy_name"
    fi
done

section Python
found=0
for name in python3.14 python3.13 python3.12 python3.11 python3.10 python3.9 python3.8 python3 python; do
    path=$(command -v "$name" 2>/dev/null || true)
    [ -n "$path" ] || continue
    version=$("$path" --version 2>&1 || true)
    printf '%-12s %-45s %s\n' "$name" "$path" "$version"
    found=1
done
[ "$found" -eq 1 ] || printf 'No Python command found on PATH.\n'

section uv
if uv_path=$(command -v uv 2>/dev/null); then
    printf 'path: %s\n' "$uv_path"
    if ! uv --version; then
        printf 'uv exists but did not run successfully.\n'
    fi
else
    printf 'uv: not found\n'
fi

printf '\nDiagnostics complete. This script made no changes.\n'

