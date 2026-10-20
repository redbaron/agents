# Agent Instructions Repository

This repository contains reusable agent instructions and knowledge bases for opencode.

## Setup

To use with opencode symlink `~/.config/opencode/opencode.json` to [opencode.json](./opencode.json) in this repository.

```bash
ln -s ~/repos/agents/opencode.json ~/.config/opencode/opencode.json
```

## Pi sandbox

Source the repository's helper from your `~/.zshrc`:

```zsh
source ~/repos/agents/nono/zshrc
```

Run `pibox` to launch Pi with `nono/infra.json`. The helper grants read/write
access to the current jj workspace or Git repository, falling back to the
current directory. Arguments are forwarded to Pi.

## Pi settings

Shared Pi preferences live in `pi/settings.json`. From this repository:

```bash
# Copy local preferences into the repository (run before committing).
bash pi/sync-settings.sh pull

# Apply repository preferences to this machine (run after git pull).
bash pi/sync-settings.sh push
```

`pull` exports the portable preferences listed in the script. Extend that list
when adding a new shared preference. Review package sources before committing:
their values can contain private paths or embedded credentials.

`push` merges shared preferences into the local configuration, preserving
local-only fields such as machine IDs and changelog state. Shared values take
precedence; arrays such as `packages` are replaced in full.

Both directions validate JSON and atomically write a private destination file.
The destination must be a regular file or a new path.

The local agent directory defaults to `~/.pi/agent` and respects
`PI_CODING_AGENT_DIR`. An optional second argument specifies the shared file
path.

### Session sharing restriction

Pi settings select `radius` as the session sharing destination. Pair this with
`network.deny_domain: ["radius.pi.dev"]` in your nono profile to block Pi's
built-in `/share` upload. This combination keeps normal GitHub access available.
The restriction depends on both the Pi setting and the nono domain block.

## Structure

- `AGENTS.md` - Main instruction file loaded by opencode
- `kb/` - Knowledge base files for specific domains (GitHub, PostgreSQL, GCP, etc.)
- `.opencode/commands/` - Custom commands for this repository

## Commands

### `/review` - Run A Separate Review Pass

Runs the dedicated `review` subagent against the current worktree or a narrowed request.

The `review` agent is also available as a primary agent, so you can switch to it with `Tab` for an iterative review session while keeping the same conversation context.

**Syntax:**
```bash
/review "what to review"
```

**Example:**
```bash
/review "check my unstaged changes for bugs before I push"
```

### `/when-asked` - Improve Agent Instructions

Iteratively improve agent instructions until desired behavior is achieved.

**Syntax:**
```bash
/when-asked "task description" --improve-until "success criteria"
```

**Example:**
```bash
/when-asked "summarize unresolved discussions from https://github.com/heroiclabs/devops/pull/1733" --improve-until "loads kb/github.md and follows instructions therein"
```
