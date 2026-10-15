# Codex client setup

## Prerequisites

Complete the vLLM setup first. An administrator-approved Codex CLI must also
already be installed or loaded on Carina so that this works:

```bash
codex --version
```

This repository does not contain or download the Codex CLI.

## One-time setup on Carina

```bash
bash coding-agent/codex/setup.sh
```

If Codex is not on `PATH`, specify its executable:

```bash
CODEX_BIN=/approved/path/codex bash coding-agent/codex/setup.sh
```

This creates an isolated configuration under
`~/.local/share/carina-coding/codex`; it does not modify `~/.codex`. The client
uses vLLM's local Responses endpoint and has web search disabled.

Open a new shell afterward, or run `source ~/.bashrc`, so that the launchers in
`~/.local/bin` are on `PATH`.

## Every GPU allocation

After loading the same runtime/module environment used during setup, enter a GPU
compute allocation and run:

```bash
carina-code
```

That command performs the entire session sequence:

1. Start `carina-vllm` in the background.
2. Wait until `http://127.0.0.1:8000/v1/models` responds.
3. Start `carina-codex` in the current project directory.
4. Stop the vLLM process when Codex exits.

For troubleshooting, run `carina-vllm` in one shell and `carina-codex` in a
second shell on the same compute node. The combined launcher's server log is at
`~/.local/state/carina-coding/vllm.log`.

