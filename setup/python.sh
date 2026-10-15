#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=setup/lib.sh
source "$SCRIPT_DIR/lib.sh"
ROOT=$(repo_root)
# shellcheck source=VERSIONS.env
source "$ROOT/VERSIONS.env"

UV_BIN=${UV_BIN:-$HOME/.local/bin/uv}
PYTHON_SOURCE=${PYTHON_SOURCE:-offline}
PYTHON_VERSION=${PYTHON_VERSION:-3.12}
TARGET=$(linux_target)
PYTHON_MIRROR="$ROOT/artifacts/python"

[ -x "$UV_BIN" ] || die "uv is not installed at $UV_BIN; run setup/uv.sh first"

python_is_requested_version() {
    local candidate=$1
    [ -x "$candidate" ] || return 1
    "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info[:2] == (3, 12) else 1)' \
        >/dev/null 2>&1
}

find_system_python() {
    local candidate path
    for candidate in python3.12 python3 python; do
        path=$(command -v "$candidate" 2>/dev/null || true)
        if [ -n "$path" ] && python_is_requested_version "$path"; then
            printf '%s\n' "$path"
            return 0
        fi
    done
    return 1
}

verify_uv_can_find_python() {
    PATH="$HOME/.local/bin:$PATH" "$UV_BIN" python find \
        --no-python-downloads "$PYTHON_VERSION" >/dev/null 2>&1
}

try_network_install() {
    note "Trying uv's normal Python $PYTHON_VERSION download..."
    UV_HTTP_TIMEOUT=${UV_HTTP_TIMEOUT:-10} \
    UV_HTTP_RETRIES=${UV_HTTP_RETRIES:-0} \
        "$UV_BIN" python install "$PYTHON_VERSION"
}

try_local_mirror() {
    local archive
    archive=$(find "$PYTHON_MIRROR" -type f \
        -name "cpython-${PYTHON_VERSION}.*-${TARGET}-install_only*.tar.gz" \
        -print -quit 2>/dev/null || true)
    [ -n "$archive" ] || return 1

    verify_recorded_sha256 "$archive" "$ROOT/artifacts/SHA256SUMS"
    note "Trying bundled python-build-standalone mirror..."
    UV_OFFLINE=1 "$UV_BIN" python install "$PYTHON_VERSION" \
        --mirror "file://$PYTHON_MIRROR" && return 0

    note "The archive does not match uv's pinned download manifest; unpacking it directly."
    install_archive "$archive"
}

install_archive() {
    local archive=$1
    local base install_parent install_dir staging extracted_python link
    base=$(basename -- "$archive")
    install_parent="$HOME/.local/share/carina-bootstrap/python"
    install_dir="$install_parent/${base%.tar.gz}"

    mkdir -p "$install_parent" "$HOME/.local/bin"
    if [ -x "$install_dir/bin/python3.12" ]; then
        note "Bundled Python is already unpacked at $install_dir"
    else
        staging=$(mktemp -d "$install_parent/.python-stage.XXXXXX")
        trap 'rm -rf -- "$staging"' EXIT
        tar -xzf "$archive" -C "$staging"
        extracted_python=$(find "$staging" \( -type f -o -type l \) \
            -path '*/bin/python3.12' -print -quit)
        [ -n "$extracted_python" ] || die "archive has no bin/python3.12: $archive"
        extracted_python=${extracted_python%/bin/python3.12}
        mkdir -p "$install_dir"
        cp -a "$extracted_python/." "$install_dir/"
        python_is_requested_version "$install_dir/bin/python3.12" || \
            die "the bundled interpreter did not run as Python 3.12 (check glibc compatibility)"
        rm -rf -- "$staging"
        trap - EXIT
        note "Installed bundled Python at $install_dir"
    fi

    link="$HOME/.local/bin/python3.12"
    if [ -L "$link" ]; then
        ln -sfn "$install_dir/bin/python3.12" "$link"
    elif [ ! -e "$link" ]; then
        ln -s "$install_dir/bin/python3.12" "$link"
    elif ! python_is_requested_version "$link"; then
        die "$link already exists but is not Python 3.12; refusing to overwrite it"
    fi
}

case "$PYTHON_SOURCE" in
    offline|auto|network|system|bundled) ;;
    *) die "PYTHON_SOURCE must be offline, auto, network, system, or bundled" ;;
esac

if verify_uv_can_find_python; then
    note "Python $PYTHON_VERSION is already available."
elif [ "$PYTHON_SOURCE" = auto ] || [ "$PYTHON_SOURCE" = network ]; then
    if try_network_install && verify_uv_can_find_python; then
        note "Installed Python $PYTHON_VERSION with uv."
    elif [ "$PYTHON_SOURCE" = network ]; then
        die "uv could not download Python $PYTHON_VERSION"
    fi
fi

if ! verify_uv_can_find_python && { [ "$PYTHON_SOURCE" = offline ] || [ "$PYTHON_SOURCE" = auto ] || [ "$PYTHON_SOURCE" = system ]; }; then
    system_python=$(find_system_python || true)
    if [ -n "$system_python" ]; then
        note "Using system Python: $system_python"
    elif [ "$PYTHON_SOURCE" = system ]; then
        die "no system Python $PYTHON_VERSION was found on PATH"
    fi
fi

if ! verify_uv_can_find_python && { [ "$PYTHON_SOURCE" = offline ] || [ "$PYTHON_SOURCE" = auto ] || [ "$PYTHON_SOURCE" = bundled ]; }; then
    try_local_mirror || die "no usable bundled Python archive for $TARGET"
fi

verify_uv_can_find_python || die "Python $PYTHON_VERSION is still unavailable to uv"
PYTHON_PATH=$(PATH="$HOME/.local/bin:$PATH" "$UV_BIN" python find \
    --no-python-downloads "$PYTHON_VERSION")
note "Python ready: $PYTHON_PATH"
note "Verified: uv can create a venv with '--python $PYTHON_VERSION --no-python-downloads'."

