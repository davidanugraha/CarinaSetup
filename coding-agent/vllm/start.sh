#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=${CARINA_VLLM_ENV:-$HOME/.config/carina-coding/vllm.env}
[ -r "$ENV_FILE" ] || {
    printf 'ERROR: vLLM configuration not found: %s\n' "$ENV_FILE" >&2
    printf '%s\n' 'Run bash coding-agent/vllm/setup.sh on Carina first.' >&2
    exit 1
}

# shellcheck source=/dev/null
source "$ENV_FILE"

: "${CARINA_VLLM_BIN:?CARINA_VLLM_BIN is missing from $ENV_FILE}"
: "${CARINA_MODEL_DIR:?CARINA_MODEL_DIR is missing from $ENV_FILE}"
: "${CARINA_MODEL_NAME:=Qwen/Qwen3.8-27B}"
: "${CARINA_TP_SIZE:=1}"
: "${CARINA_MAX_MODEL_LEN:=32768}"
: "${CARINA_VLLM_HOST:=127.0.0.1}"
: "${CARINA_VLLM_PORT:=8000}"

[ -x "$CARINA_VLLM_BIN" ] || {
    printf 'ERROR: saved vLLM executable is unavailable: %s\n' "$CARINA_VLLM_BIN" >&2
    exit 1
}
[ -r "$CARINA_MODEL_DIR/config.json" ] || {
    printf 'ERROR: saved model directory is unavailable: %s\n' "$CARINA_MODEL_DIR" >&2
    exit 1
}

export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export HF_HUB_DISABLE_TELEMETRY=1

exec "$CARINA_VLLM_BIN" serve "$CARINA_MODEL_DIR" \
    --served-model-name "$CARINA_MODEL_NAME" \
    --host "$CARINA_VLLM_HOST" \
    --port "$CARINA_VLLM_PORT" \
    --tensor-parallel-size "$CARINA_TP_SIZE" \
    --max-model-len "$CARINA_MAX_MODEL_LEN" \
    --reasoning-parser qwen3 \
    --enable-auto-tool-choice \
    --tool-call-parser qwen3_coder \
    "$@"

