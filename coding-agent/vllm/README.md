# vLLM and Qwen3.8 setup

## Prerequisite

An administrator-approved vLLM environment must already be installed or loaded
on Carina. For example, load the appropriate cluster module or activate the
approved virtual environment so that this works:

```bash
vllm --version
```

This repository deliberately does not install vLLM from public PyPI and does
not contain wheels or Python packages.

## One-time setup on Carina

For a model in the default Hugging Face cache:

```bash
bash coding-agent/vllm/setup.sh
```

For a model or Hugging Face cache in another location, pass that location and
the number of GPUs that vLLM should use:

```bash
bash coding-agent/vllm/setup.sh /path/to/model-or-hf-cache 4
```

The setup verifies that the model files are readable and that the loaded vLLM
contains the `qwen3_coder` parser required for Qwen3.8. It then installs the
`carina-vllm` launcher in `~/.local/bin`.

If vLLM is not on `PATH`, specify its executable explicitly:

```bash
VLLM_BIN=/approved/venv/bin/vllm bash coding-agent/vllm/setup.sh /path/to/model 4
```

The saved settings are in:

```text
~/.config/carina-coding/vllm.env
```

The default context length is 32768 instead of the model maximum of 262144 to
avoid an unexpectedly large KV cache. The launcher forces Hugging Face and
Transformers offline mode and binds the API to `127.0.0.1`.

