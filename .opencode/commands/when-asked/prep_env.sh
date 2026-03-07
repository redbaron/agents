#!/usr/bin/env bash
set -ue
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

log () { echo "$(date -u -Iseconds)" "[$1]" "${@:2}" >&2 ; }
info () { log "INFO" "$@" ; }
fatal () { log "FATAL" "$@"; exit 1 ; }

prepare_test_env () {
	TEST_ENV_DIR="${SCRIPT_DIR}/test-env"
	
	[[ -d "$TEST_ENV_DIR" ]] || mkdir -p "$TEST_ENV_DIR"
	echo "$TEST_ENV_DIR"
}

start_http_server () {
	pgrep -f "python3 -m http.server 8766" > /dev/null && {
		info "HTTP server already running on port 8766"
		return 0
	}
	
	info "Starting HTTP server on port 8766"
	python3 -m http.server 8766 > /tmp/agents-http.log 2> /dev/null &
}

prepare_test_env
start_http_server
