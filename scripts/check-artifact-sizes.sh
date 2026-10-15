#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
status=0
while IFS= read -r -d '' file; do
    size=$(wc -c < "$file")
    printf '%10s  %s\n' "$size" "${file#"$ROOT/"}"
    if [ "$size" -ge 100000000 ]; then
        echo '  ERROR: exceeds GitHub regular-file limit (100,000,000 bytes)' >&2
        status=1
    elif [ "$size" -ge 95000000 ]; then
        echo '  WARNING: close to GitHub regular-file limit' >&2
    fi
done < <(find "$ROOT/artifacts" -type f ! -name README.md -print0 | sort -z)
exit "$status"

