# Bash Style Guide

## Preamble

```bash
#!/usr/bin/env bash
set -ue
set -o pipefail
```

Always `#!/usr/bin/env bash` — never `#!/bin/bash`. macOS ships bash 3.2;
`/usr/bin/env` picks up a modern bash (4+/5+) from Homebrew or Nix.

Validate required env vars immediately with `: "${VAR:?message}"`.

## Helper Functions

Define short, single-line helpers for repeated operations — logging, command
wrappers, etc. Keep names terse (single letter is fine for wrappers). Pass
through args with `"$@"`.

```bash
k () { kubectl --context "${CTX}" -n "${NS}" "$@" ; }
log () { echo "$(date -u -Iseconds)" "[$1]" "$@" >&2 ; }
info () { log "INFO" "$@" ; }
fatal () { log "FATAL" "$@"; exit 1 ; }
```

All human-facing output goes to stderr. Stdout is for machine-parseable data.

## Shared Libraries

Factor reusable helpers into a `lib.sh` and source it via:

```bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib.sh"
```

## String Operations

Prefer bash parameter expansion over `cut`/`awk`/`sed`:

```bash
IMG_TAG=${CNPG_IMG#*:}       # strip prefix up to first ':'
PG_MAJOR=${IMG_TAG%%.*}      # strip suffix from first '.'
```

For JSON, use `jq` with `--arg` — never interpolate variables into JSON strings:

```bash
jq -c --arg IMG "${NEW_IMG}" -n '.spec.imageName=$IMG'
```

## Flow Control

The pattern is: **assert the happy path, handle deviation inline**.
Avoid `if`/`then`/`fi` when a concise `||`/`&&` chain is readable.

```bash
[[ -n "${CNPG}" ]] || exit 0
[[ "$STATUS" == "Cluster in healthy state" ]] || fatal "unhealthy" "$STATUS"
[[ -z "${NEW_IMG}" ]] || {
    update_image
    update_database_crd
}
```

Use `|| :` to suppress errors from commands that may fail under `set -e`.

Use `[[ ]]` for tests, `(( ))` for arithmetic.

## Cleanup Traps

Use `trap ... EXIT` with an `EXIT_CODE` guard so cleanup distinguishes
success from failure:

```bash
EXIT_CODE=1
cleanup () {
    stop_proxy
    if [[ $EXIT_CODE -ne 0 ]]; then
        info "FAILED — cleaning up..."
        rollback_changes || true
    fi
}
trap cleanup EXIT
# ... main work ...
EXIT_CODE=0
```

Cleanup actions that may fail get `|| true` to avoid masking the real error.

## Variables

- **UPPER_CASE** for globals and env vars.
- **`_PREFIXED`** for temporaries / loop locals.
- `local` for function-scoped variables.
- Always double-quote expansions: `"$VAR"`, `"$@"`.
- Use `${VAR:?error}` over silent defaults.
- Use `declare -A` for associative arrays when mapping keys to values.

## Functions

- `name()` syntax (no `function` keyword).
- `local` all variables that don't need to escape the function.
- `return` for non-fatal early exit; `exit` only at top level or in `fatal`.
- Use `## Section name` comments to group related code.

## Capturing Output

```bash
read -r A B C < <(command)           # multiple fields
readarray -t LINES < <(command)      # array of lines
```
