#!/usr/bin/env bash
set -ue
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

log () { echo "$(date -u -Iseconds)" "[$1]" "${@:2}" >&2 ; }
info () { log "INFO" "$@" ; }
fatal () { log "FATAL" "$@"; exit 1 ; }

parse_args () {
	[[ $# -ge 2 ]] || fatal "Usage: $0 TASK MODEL"
	
	TASK="$1"
	MODEL="$2"
}

clear_http_log () {
	info "Clearing HTTP server log"
	: > /tmp/agents-http.log
}

run_opencode () {
	local TEST_ENV_DIR="${SCRIPT_DIR}/test-env"
	local CONFIG_PATH="${SCRIPT_DIR}/improve-test-config.json"
	local ORIG_HOME="$HOME"
	
	[[ -d "$TEST_ENV_DIR" ]] || mkdir -p "$TEST_ENV_DIR"
	
	info "Running opencode test with model: $MODEL"
	info "Task: $TASK"
	
	cd "$TEST_ENV_DIR"
	XDG_DATA_HOME="$ORIG_HOME/.local/share" \
		HOME=$(mktemp -d) \
		OPENCODE_CONFIG="$CONFIG_PATH" \
		opencode run -m "$MODEL" message "$TASK"
}

parse_args "$@"
clear_http_log
run_opencode
