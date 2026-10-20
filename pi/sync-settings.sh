#!/usr/bin/env bash
set -ue
set -o pipefail

# Only these preferences cross the machine/repository boundary.
KEYS='["defaultTools", "defaultProvider", "defaultModel", "defaultThinkingLevel", "packages", "showHardwareCursor", "sessionShareDestination", "treeFilterMode", "tuiMode"]'

sync_settings() {
    [[ $# -ge 1 && $# -le 2 && ( "$1" == pull || "$1" == push ) ]] || {
        echo "Usage: $0 pull|push [shared-settings.json]" >&2
        echo 'pull: local Pi settings -> repository; push: repository -> local Pi settings' >&2
        exit 1
    }
    : "${HOME:?HOME must be set}"
    local shared local_file source destination content temporary
    shared=${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/settings.json}
    local_file=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/settings.json
    source=$local_file
    destination=$shared
    [[ "$1" == pull ]] || { source=$shared; destination=$local_file; }
    [[ ! -L "$destination" ]] || {
        echo "Refusing to replace symlink: $destination" >&2
        exit 1
    }
    # Validate before touching the destination; reject unknown shared fields on push.
    content=$(jq -es --argjson keys "$KEYS" --arg direction "$1" '
        if length != 1 or (.[0] | type) != "object" then
            error("settings must contain exactly one JSON object")
        else .[0] end
        | if $direction == "push" and ((keys - $keys) | length) > 0 then
            error("shared settings contain fields outside the shareable list")
          else with_entries(select(.key as $key | $keys | index($key))) end
    ' "$source")
    if [[ "$1" == push && -e "$local_file" ]]; then
        content=$(jq -es --argjson shared "$content" '
            if length != 1 or (.[0] | type) != "object" then
                error("local settings must contain exactly one JSON object")
            else .[0] + $shared end
        ' "$local_file")
    fi
    mkdir -p "$(dirname "$destination")"
    temporary=$(mktemp "${destination}.XXXXXX")
    printf '%s\n' "$content" > "$temporary"
    mv "$temporary" "$destination"
    echo "Updated $destination" >&2
}

sync_settings "$@"
