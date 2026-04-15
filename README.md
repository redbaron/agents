# Agent Instructions Repository

This repository contains reusable agent instructions and knowledge bases for opencode.

## Setup

To use with opencode symlink `~/.config/opencode/opencode.json` to [opencode.json](./opencode.json) in this repository.

```bash
ln -s ~/repos/agents/opencode.json ~/.config/opencode/opencode.json
```

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
