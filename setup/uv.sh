#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=setup/lib.sh
source "$SCRIPT_DIR/lib.sh"
ROOT=$(repo_root)
# shellcheck source=VERSIONS.env
source "$ROOT/VERSIONS.env"

UV_SOURCE=${UV_SOURCE:-auto}
TARGET=$(linux_target)
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/uv"
BUNDLED="$ROOT/artifacts/uv/$TARGET/uv"
SUMS="$ROOT/artifacts/SHA256SUMS"

install_bundled() {
    [ -f "$BUNDLED" ] || return 1
    verify_recorded_sha256 "$BUNDLED" "$SUMS"
    install -m 0755 "$BUNDLED" "$INSTALL_PATH"
    note "Installed bundled uv for $TARGET."
}

install_downloaded() {
    local url checksum_url tmp archive expected actual extracted
    command -v curl >/dev/null 2>&1 || die "curl is required for download mode"
    url="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${TARGET}.tar.gz"
    checksum_url="$url.sha256"
    tmp=$(mktemp -d)
    trap 'rm -rf -- "$tmp"' EXIT
    archive="$tmp/uv.tar.gz"

    note "Downloading uv $UV_VERSION for $TARGET..."
    curl --fail --location --silent --show-error \
        --connect-timeout 10 --max-time 120 "$url" -o "$archive"
    expected=$(curl --fail --location --silent --show-error \
        --connect-timeout 10 --max-time 30 "$checksum_url" | awk '{print $1}')
    [ -n "$expected" ] || die "downloaded uv checksum is empty"
    actual=$(sha256_file "$archive")
    [ "$actual" = "$expected" ] || die "downloaded uv archive failed SHA-256 verification"

    tar -xzf "$archive" -C "$tmp"
    extracted="$tmp/uv-${TARGET}/uv"
    [ -f "$extracted" ] || die "unexpected uv archive layout"
    install -m 0755 "$extracted" "$INSTALL_PATH"
    rm -rf -- "$tmp"
    trap - EXIT
    note "Installed downloaded uv $UV_VERSION."
}

case "$UV_SOURCE" in
    auto|bundled|download) ;;
    *) die "UV_SOURCE must be auto, bundled, or download" ;;
esac

mkdir -p "$INSTALL_DIR"
if [ -x "$INSTALL_PATH" ] && "$INSTALL_PATH" --version >/dev/null 2>&1; then
    note "uv is already installed at $INSTALL_PATH: $($INSTALL_PATH --version)"
elif [ "$UV_SOURCE" = bundled ]; then
    install_bundled || die "bundled uv binary not found for $TARGET"
elif [ "$UV_SOURCE" = download ]; then
    install_downloaded
elif ! install_bundled; then
    note "No bundled uv binary found for $TARGET; trying GitHub release assets."
    install_downloaded
fi

chmod +x "$INSTALL_PATH"
ensure_path_line "$HOME/.bashrc"
export PATH="$INSTALL_DIR:$PATH"
"$INSTALL_PATH" --version

if [ "${SKIP_PYTHON:-0}" != 1 ]; then
    UV_BIN="$INSTALL_PATH" bash "$SCRIPT_DIR/python.sh"
fi

note "Setup complete. Open a new shell or run: source ~/.bashrc"

