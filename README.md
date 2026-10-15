# Carina bootstrap

Small, user-local bootstrap scripts for `uv` and Python 3.12 on an air-gapped
Linux cluster. Nothing needs root access. No package installation from PyPI is
configured by this repository.

## First: diagnose Carina

Type these commands on Carina and share the complete output of `check.sh` before
running setup:

```bash
git clone https://github.com/davidanugraha/CarinaSetup.git cs
bash cs/check.sh
```

The diagnostic is read-only. It reports architecture, glibc/`ldd`, short
connectivity probes for GitHub and GitHub release assets, available Python
commands, and whether `uv` already works.

## Install

After the diagnostic has confirmed compatibility and the transfer method has
been approved by the Carina administrators:

```bash
bash cs/setup.sh
```

The setup script:

1. Detects `x86_64` or `aarch64`.
2. Installs a checksum-verified bundled `uv` binary to `~/.local/bin/uv`. If no
   bundled binary exists, it tries the pinned GitHub release asset.
3. Adds `export PATH="$HOME/.local/bin:$PATH"` to `~/.bashrc` once.
4. Tries `uv python install 3.12`, then a system Python 3.12 with downloads
   disabled, then a bundled python-build-standalone archive.
5. Verifies `uv --version` and that `uv` can find Python 3.12 without another
   download.

Open a new shell afterward, or run `source ~/.bashrc`. A virtual environment can
then be created without a Python download:

```bash
uv venv --python 3.12 --no-python-downloads
```

## Offline assets

Pinned versions are in `VERSIONS.env`. Run `bash scripts/fetch-uv.sh` on an
internet-connected trusted machine before pushing the repo to populate both
bundled `uv` binaries.

For the Python fallback, run `bash scripts/fetch-python.sh` to download the
pinned GNU/Linux `install_only_stripped` CPython 3.12 archives for both
architectures and verify the upstream checksums. Alternatively, download one
from the official python-build-standalone release page and run
`bash scripts/stage-python.sh PATH`. Run
`bash scripts/check-artifact-sizes.sh` before committing. GitHub rejects normal
Git files at 100,000,000 bytes; if an archive is larger, Git LFS only works if
LFS downloads work on Carina, while a GitHub release asset only works if the
release-assets probe succeeds.

Force a source when troubleshooting:

```bash
UV_SOURCE=bundled PYTHON_SOURCE=bundled bash cs/setup.sh
UV_SOURCE=download PYTHON_SOURCE=network bash cs/setup.sh
PYTHON_SOURCE=system bash cs/setup.sh
```

## Policy boundary

This repo may contain only the setup scripts, official `uv` executables, and an
approved standalone Python runtime. Never add credentials, tokens, data, Python
packages, wheels, or source distributions. Package installation is deliberately
not configured until an approved internal package index is known.

## Optional local coding assistant

This is intentionally not installed by `setup.sh`. A useful offline assistant
needs separate approval, a compatible GPU/CPU and memory allocation, and large
model/runtime artifacts transferred through an approved route. OpenCode can use
an OpenAI-compatible local server. Codex CLI may also support custom providers,
but its exact installation and provider configuration should be pinned only
after choosing the runtime and model. OpenAI's local `gpt-oss` options include
20B and 120B models; those model weights are far larger than this bootstrap repo
and must not be added here.

