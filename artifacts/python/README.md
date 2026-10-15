# Bundled Python archive

Place a CPython 3.12 `install_only` or `install_only_stripped` `.tar.gz` from
Astral's `python-build-standalone` releases here by running:

```bash
bash scripts/stage-python.sh /path/to/cpython-3.12...install_only_stripped.tar.gz
```

The staging script creates the local-mirror layout and updates
`artifacts/SHA256SUMS`. Do not place Python packages, wheels, or source
distributions here.

To fetch the two archives pinned in `VERSIONS.env` directly from the official
release and verify them against its `SHA256SUMS`, run:

```bash
bash scripts/fetch-python.sh
```

