---
description: Iterate on agent instructions until desired behavior is achieved
agent: build
---

You are tasked with improving agent instructions in the current repository.

**Test task:** $1
**Success criteria:** $2

**Workflow:**
1. Start HTTP server on port 8766 serving the current directory if not already running: `python3 -m http.server 8766 > /tmp/agents-http.log 2> /dev/null &`
2. Edit the instruction files (AGENTS.md or kb/*.md files) to achieve the success criteria
3. Clear the HTTP server log: `> /tmp/agents-http.log`
4. Determine the current model from your system context (e.g., "opencode-go/glm-5" or "anthropic/claude-sonnet-4-5")
5. Run the test in an empty directory with isolated config but shared credentials:
   ```bash
   CONFIG_PATH="$(pwd)/.opencode/commands/improve-test-config.json" ORIG_HOME="$HOME" && cd $(mktemp -d) && XDG_DATA_HOME="$ORIG_HOME/.local/share" HOME=$(mktemp -d) OPENCODE_CONFIG="$CONFIG_PATH" opencode run -m <CURRENT_MODEL> message "$1"
   ```
6. Check the HTTP server log to verify which files were loaded: `grep "GET" /tmp/agents-http.log`
7. Analyze the test output and logs to determine if the success criteria was achieved
8. If not achieved, iterate: make more edits and re-test
9. Continue until the agent achieves the success criteria without additional nudging

**What to check:**
- HTTP logs should show GET requests to the relevant /kb/*.md files
- Test output should demonstrate the agent followed knowledge base instructions correctly
- No manual intervention or additional hints beyond the test task

**Test environment notes:**
- HTTP server stderr redirected to /dev/null to avoid tracebacks
- Current model is extracted from system context and passed via `-m` flag
- `HOME=$(mktemp -d)` prevents loading ~/.config/opencode/opencode.json
- `XDG_DATA_HOME=~/.local/share` preserves provider credentials
- `OPENCODE_CONFIG` points to static test config file
- Bash is denied to isolate the test to just knowledge base loading behavior
- WebFetch is allowed so the agent can load knowledge bases from HTTP server

Keep the HTTP server running between iterations for faster testing. Stop it with `pkill -f "python3 -m http.server 8766"` when done.
