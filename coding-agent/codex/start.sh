#!/usr/bin/env bash
set -euo pipefail

# Installed as ~/.local/bin/carina-codex by coding-agent/codex/setup.sh.

CONFIG_DIR=${CARINA_CODING_CONFIG_DIR:-$HOME/.config/carina-coding}
VLLM_ENV="$CONFIG_DIR/vllm.env"
CODEX_ENV="$CONFIG_DIR/codex.env"

[ -r "$VLLM_ENV" ] || {
    printf 'ERROR: missing vLLM configuration: %s\n' "$VLLM_ENV" >&2
    exit 1
}
[ -r "$CODEX_ENV" ] || {
    printf 'ERROR: missing Codex configuration: %s\n' "$CODEX_ENV" >&2
    exit 1
}

# shellcheck source=/dev/null
source "$VLLM_ENV"
# shellcheck source=/dev/null
source "$CODEX_ENV"

: "${CARINA_CODEX_BIN:?CARINA_CODEX_BIN is missing from $CODEX_ENV}"
: "${CARINA_CODEX_HOME:?CARINA_CODEX_HOME is missing from $CODEX_ENV}"
: "${CARINA_VLLM_HOST:=127.0.0.1}"
: "${CARINA_VLLM_PORT:=8000}"
: "${CARINA_MAX_MODEL_LEN:=32768}"

[ -x "$CARINA_CODEX_BIN" ] || {
    printf 'ERROR: saved Codex executable is unavailable: %s\n' "$CARINA_CODEX_BIN" >&2
    exit 1
}
case "$CARINA_VLLM_HOST" in
    ''|*[!A-Za-z0-9._-]*)
        printf 'ERROR: invalid CARINA_VLLM_HOST: %s\n' "$CARINA_VLLM_HOST" >&2
        exit 1
        ;;
esac
case "$CARINA_VLLM_PORT" in
    ''|*[!0-9]*)
        printf 'ERROR: invalid CARINA_VLLM_PORT: %s\n' "$CARINA_VLLM_PORT" >&2
        exit 1
        ;;
esac
case "$CARINA_MAX_MODEL_LEN" in
    ''|*[!0-9]*|0)
        printf 'ERROR: invalid CARINA_MAX_MODEL_LEN: %s\n' "$CARINA_MAX_MODEL_LEN" >&2
        exit 1
        ;;
esac

provider_url="http://$CARINA_VLLM_HOST:$CARINA_VLLM_PORT/v1"
export CODEX_HOME=$CARINA_CODEX_HOME
exec "$CARINA_CODEX_BIN" \
    --config "model_providers.vllm.base_url=\"$provider_url\"" \
    --config "model_context_window=$CARINA_MAX_MODEL_LEN" \
    "$@"

