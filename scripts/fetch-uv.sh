#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=VERSIONS.env
source "$ROOT/VERSIONS.env"

command -v curl >/dev/null 2>&1 || { echo 'ERROR: curl is required' >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo 'ERROR: sha256sum is required' >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$ROOT/artifacts/uv"

for target in x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu; do
    url="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${target}.tar.gz"
    archive="$tmp/uv-${target}.tar.gz"
    echo "Fetching $url"
    curl --fail --location --silent --show-error "$url" -o "$archive"
    expected=$(curl --fail --location --silent --show-error "$url.sha256" | awk '{print $1}')
    actual=$(sha256sum "$archive" | awk '{print $1}')
    [ "$actual" = "$expected" ] || { echo "ERROR: checksum mismatch for $target" >&2; exit 1; }
    tar -xzf "$archive" -C "$tmp"
    mkdir -p "$ROOT/artifacts/uv/$target"
    install -m 0755 "$tmp/uv-$target/uv" "$ROOT/artifacts/uv/$target/uv"
done

(
    cd "$ROOT/artifacts"
    find uv python -type f ! -name README.md -print0 2>/dev/null | \
        sort -z | xargs -0 -r sha256sum
) > "$tmp/SHA256SUMS"
mv "$tmp/SHA256SUMS" "$ROOT/artifacts/SHA256SUMS"
echo "Bundled uv binaries and checksums are ready under $ROOT/artifacts."

