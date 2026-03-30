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

## JSON and jq

Treat `jq` as a standard tool — always available, no need to guard its presence.
Use it freely instead of `grep`/`awk`/`sed` pipelines for any JSON work.

### Store related state as a JSON object

When a function produces multiple related fields, store them together in a single
JSON object variable rather than scattering them into individual globals. Callers
extract only what they need at the point of use:

```bash
# producer
instance_info=$(jq '{
    endpoint:   .Endpoint.Address,
    vpc_id:     .DBSubnetGroup.VpcId,
    subnet_ids: [.DBSubnetGroup.Subnets[].SubnetIdentifier],
    sg_ids:     [.VpcSecurityGroups[].VpcSecurityGroupId]
}' <<< "$raw")

# consumer — extract inline, only what's needed
endpoint=$(jq -r '.endpoint' <<< "$instance_info")
subnet_ids=$(jq -c '.subnet_ids' <<< "$instance_info")
```

This avoids a proliferation of `_ENDPOINT`, `_VPC_ID`, `_SUBNET_IDS` globals that
are just carriers for a single structured value.

### Delegate assertions to jq

Use `// error("message")` for null checks inline in the same `jq` call that does
the extraction. `jq` prints the message to stderr and exits non-zero; `set -e`
aborts the script and fires the EXIT trap. No need to duplicate the message in a
`|| fatal`:

```bash
# jq prints the error, set -e aborts — no || fatal needed
raw=$(aws rds describe-db-instances ... \
    | jq --arg id "$db_id" \
        '.DBInstances[0] // error("RDS instance \($id) not found")')

info_json=$(jq --arg id "$db_id" '{
    endpoint: (.Endpoint.Address // error("RDS instance \($id) has no endpoint")),
    vpc_id:   .DBSubnetGroup.VpcId
}' <<< "$raw")
```

### Use -e to branch on boolean results

`jq -e` exits non-zero when the output is `false` or `null`, so boolean filters
drive `if`/`||` directly without capturing output into a variable:

```bash
if jq -e '.enabled' <<< "$raw" >/dev/null; then
    do_thing
fi
```

### Keep lists in JSON when already in JSON

If a list originates from JSON or is being passed to/from `jq`, keep it as a
JSON array throughout — don't convert to space-delimited strings or bash arrays
mid-flight. Iterate with `jq -r '.[]'` into a `while read` loop:

```bash
while IFS= read -r item; do
    process "$item"
done < <(jq -r '.[]' <<< "$json_array")
```

Use bash arrays when the data originates in bash and never needs to cross a JSON
boundary.

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

Split cleanup into separate functions and use `trap ... EXIT` with `$?` checking
to distinguish success from failure:

```bash
cleanup_on_failure () {
    info "FAILED — cleaning up..."
    rollback_changes || true
}

cleanup_handler () {
    local exit_code=$?
    stop_service
    (( exit_code == 0 )) || cleanup_on_failure
}
trap cleanup_handler EXIT
```

The EXIT trap captures `$?` before the shell exits, allowing conditional cleanup
based on whether the script succeeded or failed.

Cleanup actions that may fail get `|| true` to avoid masking the real error.

## Variables

- **UPPER_CASE** for globals and env vars.
- **`_PREFIXED`** for temporaries / loop locals.
- `local` for function-scoped variables.
- Always double-quote expansions: `"$VAR"`, `"$@"`.
- Use `${VAR:?error}` over silent defaults.
- Use `declare -A` for associative arrays when mapping keys to values.
- Prefer a single JSON object variable over multiple related scalar globals — extract fields at the point of use with `jq`.

## Functions

- `name()` syntax (no `function` keyword).
- `local` all variables that don't need to escape the function.
- For single-argument functions, use `$1` directly — no need for `local name="$1"`.
- `return` for non-fatal early exit; `exit` only at top level or in `fatal`.
- Use `## Section name` comments to group related code.

## Script Structure

Group related statements into functions so the main flow reads as a short,
linear sequence of high-level steps. Each function should represent one
logical step — for example, argument parsing *and* input validation *and*
global initialisation are one step (`parse_args`), not three.

Define all functions first, then have the main flow at the bottom:

```bash
parse_args () { ... }
setup_connectivity () { ... }
save_state () { ... }
do_work () { ... }
restore_state () { ... }
cleanup_proxy () { ... }
cleanup_failure () { ... }
cleanup_handler () { ... }

parse_args "$@"
trap cleanup_handler EXIT
setup_connectivity
save_state
do_work
restore_state
```

Functions communicate via globals (UPPER_CASE). Document which globals a
function sets when it is not obvious from the name (`## ...; sets BACKUP_ID`).

Optional steps use guard-style invocation rather than if/else:

```bash
[[ -z "$SLOT_NAME" ]] || create_replication_slot
```

## Capturing Output

```bash
read -r A B C < <(command)           # multiple fields
readarray -t LINES < <(command)      # array of lines
```

## Validation

Always run `shellcheck` on bash scripts after editing:

```bash
shellcheck -s bash script.sh
```

Address all warnings before considering the script complete.
