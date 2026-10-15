#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ARCHIVE=${1:-}
[ -n "$ARCHIVE" ] || { echo "Usage: $0 PATH_TO_INSTALL_ONLY_TAR_GZ" >&2; exit 2; }
[ -f "$ARCHIVE" ] || { echo "ERROR: file not found: $ARCHIVE" >&2; exit 1; }

base=$(basename -- "$ARCHIVE")
case "$base" in
    cpython-3.12.*-x86_64-unknown-linux-gnu-install_only*.tar.gz|\
    cpython-3.12.*-aarch64-unknown-linux-gnu-install_only*.tar.gz) ;;
    *)
        echo 'ERROR: expected a CPython 3.12 install_only .tar.gz for x86_64 or aarch64 Linux GNU' >&2
        exit 1
        ;;
esac

release=$(printf '%s\n' "$base" | sed -n 's/^cpython-3\.12\.[0-9][0-9]*+\([0-9][0-9]*\)-.*/\1/p')
[ -n "$release" ] || { echo "ERROR: cannot read build release from filename: $base" >&2; exit 1; }

dest="$ROOT/artifacts/python/$release/$base"
mkdir -p "$(dirname -- "$dest")"
cp -p "$ARCHIVE" "$dest"

tmp=$(mktemp)
trap 'rm -f -- "$tmp"' EXIT
(
    cd "$ROOT/artifacts"
    find uv python -type f ! -name README.md -print0 2>/dev/null | sort -z | xargs -0 -r sha256sum
) > "$tmp"
mv "$tmp" "$ROOT/artifacts/SHA256SUMS"

size=$(wc -c < "$dest")
if [ "$size" -ge 100000000 ]; then
    echo "WARNING: $base is $size bytes and exceeds GitHub's 100 MB regular-file limit."
    echo 'Use Git LFS (only if Carina supports it) or a GitHub release asset (only if reachable).'
else
    echo "Staged $dest ($size bytes; below GitHub's 100 MB per-file limit)."
fi

