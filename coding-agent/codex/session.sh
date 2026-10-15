#!/usr/bin/env bash
set -euo pipefail

# Installed as ~/.local/bin/carina-code by coding-agent/codex/setup.sh.

CONFIG_DIR=${CARINA_CODING_CONFIG_DIR:-$HOME/.config/carina-coding}
VLLM_ENV="$CONFIG_DIR/vllm.env"
[ -r "$VLLM_ENV" ] || {
    printf 'ERROR: missing vLLM configuration: %s\n' "$VLLM_ENV" >&2
    exit 1
}

# shellcheck source=/dev/null
source "$VLLM_ENV"
: "${CARINA_VLLM_HOST:=127.0.0.1}"
: "${CARINA_VLLM_PORT:=8000}"
: "${CARINA_VLLM_START_TIMEOUT:=600}"

command -v carina-vllm >/dev/null 2>&1 || {
    printf '%s\n' 'ERROR: carina-vllm is missing; rerun coding-agent/vllm/setup.sh.' >&2
    exit 1
}
command -v carina-codex >/dev/null 2>&1 || {
    printf '%s\n' 'ERROR: carina-codex is missing; rerun coding-agent/codex/setup.sh.' >&2
    exit 1
}
command -v curl >/dev/null 2>&1 || {
    printf '%s\n' 'ERROR: curl is required for the local vLLM readiness check.' >&2
    exit 1
}
case "$CARINA_VLLM_START_TIMEOUT" in
    ''|*[!0-9]*|0)
        printf 'ERROR: invalid CARINA_VLLM_START_TIMEOUT: %s\n' \
            "$CARINA_VLLM_START_TIMEOUT" >&2
        exit 1
        ;;
esac

models_url="http://$CARINA_VLLM_HOST:$CARINA_VLLM_PORT/v1/models"
server_pid=

cleanup() {
    if [ -n "$server_pid" ] && kill -0 "$server_pid" 2>/dev/null; then
        printf '%s\n' 'Stopping the vLLM server...'
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT

if curl --silent --fail --max-time 1 "$models_url" >/dev/null 2>&1; then
    printf '%s\n' 'Using the vLLM server already running on this compute node.'
else
    state_dir="$HOME/.local/state/carina-coding"
    mkdir -p "$state_dir"
    log_file="$state_dir/vllm.log"
    printf 'Starting vLLM; log: %s\n' "$log_file"
    carina-vllm > "$log_file" 2>&1 &
    server_pid=$!

    elapsed=0
    while ! curl --silent --fail --max-time 1 "$models_url" >/dev/null 2>&1; do
        if ! kill -0 "$server_pid" 2>/dev/null; then
            wait "$server_pid" 2>/dev/null || true
            printf '%s\n' 'ERROR: vLLM exited before becoming ready. Last log lines:' >&2
            tail -n 50 "$log_file" >&2 || true
            exit 1
        fi
        if [ "$elapsed" -ge "$CARINA_VLLM_START_TIMEOUT" ]; then
            printf 'ERROR: vLLM was not ready after %s seconds. Last log lines:\n' \
                "$CARINA_VLLM_START_TIMEOUT" >&2
            tail -n 50 "$log_file" >&2 || true
            exit 1
        fi
        if [ $((elapsed % 10)) -eq 0 ]; then
            printf 'Waiting for vLLM (%ss)...\n' "$elapsed"
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    printf '%s\n' 'vLLM is ready.'
fi

carina-codex "$@"

