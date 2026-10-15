#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=VERSIONS.env
source "$ROOT/VERSIONS.env"

command -v curl >/dev/null 2>&1 || { echo 'ERROR: curl is required' >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo 'ERROR: sha256sum is required' >&2; exit 1; }

base_url="https://github.com/astral-sh/python-build-standalone/releases/download/$PYTHON_BUILD"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
curl --fail --location --silent --show-error "$base_url/SHA256SUMS" -o "$tmp/upstream-SHA256SUMS"

for target in x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu; do
    filename="cpython-${PYTHON_PATCH_VERSION}+${PYTHON_BUILD}-${target}-install_only_stripped.tar.gz"
    encoded_filename="cpython-${PYTHON_PATCH_VERSION}%2B${PYTHON_BUILD}-${target}-install_only_stripped.tar.gz"
    expected=$(awk -v wanted="$filename" '$2 == wanted {print $1; exit}' "$tmp/upstream-SHA256SUMS")
    [ -n "$expected" ] || { echo "ERROR: upstream checksum missing for $filename" >&2; exit 1; }

    archive="$tmp/$filename"
    echo "Fetching $filename"
    curl --fail --location --silent --show-error \
        "$base_url/$encoded_filename" -o "$archive"
    actual=$(sha256sum "$archive" | awk '{print $1}')
    [ "$actual" = "$expected" ] || { echo "ERROR: checksum mismatch for $filename" >&2; exit 1; }
    bash "$ROOT/scripts/stage-python.sh" "$archive"
done

echo "Bundled Python archives and checksums are ready under $ROOT/artifacts."
