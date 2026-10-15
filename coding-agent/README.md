# Carina coding agent

Everything in this directory is intended to be run **on Carina**, after cloning
this repository there. Do not run these scripts on the personal PC or CPI.

The top-level `setup/` directory contains internal helpers used by the root
`setup.sh`. Ignore it when following the coding-agent instructions below.

There are three separate one-time tasks:

1. Run the repository's root `setup.sh` to install bundled `uv` and make Python
   3.12 available.
2. [`vllm`](vllm/README.md): verify an approved vLLM runtime,
   locate the already-downloaded Qwen3.8 model, and install `carina-vllm`.
3. [`codex`](codex/README.md): verify an approved Codex CLI,
   configure it for the local vLLM server, and install `carina-code`.

## Exact order on Carina

First, run the base bootstrap once:

```bash
bash setup.sh
```

After an approved vLLM runtime is installed or loaded, configure the Qwen server
once. Replace the path and GPU count with the Carina values:

```bash
vllm --version
bash coding-agent/vllm/setup.sh /path/to/model-or-hf-cache 4
```

After an approved Codex CLI is installed or loaded, configure the client once:

```bash
codex --version
bash coding-agent/codex/setup.sh
source ~/.bashrc
```

The repository cannot supply vLLM, its Python dependencies, Codex CLI, or model
weights under the stated transfer policy. Those must already be available on
Carina through an administrator-approved module, environment, container, package
mirror, or other approved transfer route. The setup scripts detect and explain
missing prerequisites; they never contact the internet.

After all three one-time tasks, the normal per-allocation command is simply:

```bash
carina-code
```

Run it inside a GPU compute allocation, not on a login node. It starts vLLM,
waits for the API, launches Codex, and stops the vLLM process when Codex exits.
Normally, you do **not** need to run `carina-vllm` and `carina-codex` separately;
those commands exist for troubleshooting.

