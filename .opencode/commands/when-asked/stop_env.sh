#!/usr/bin/env bash
set -ue
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

log () { echo "$(date -u -Iseconds)" "[$1]" "${@:2}" >&2 ; }
info () { log "INFO" "$@" ; }

cleanup_test_env () {
	local TEST_ENV_DIR="${SCRIPT_DIR}/test-env"
	
	[[ -d "$TEST_ENV_DIR" ]] || {
		info "Test env directory does not exist: $TEST_ENV_DIR"
		return 0
	}
	
	info "Cleaning test env directory"
	rm -rf "${TEST_ENV_DIR:?}"/*
	rm -rf "${TEST_ENV_DIR:?}"/.??*
}

stop_http_server () {
	info "Stopping HTTP server"
	pkill -f "python3 -m http.server 8766" || true
}

cleanup_test_env
stop_http_server
