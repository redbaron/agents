---
description: "Iterate on agent instructions until behavior achieved. Syntax: /when-asked 'task' --improve-until 'success criteria'"
agent: build
---

You are tasked with improving agent instructions in the current repository.

**Test task:** $1
**Success criteria:** $3

**Workflow:**
1. Start the test environment: `bash .opencode/commands/when-asked/prep_env.sh`
2. Edit the instruction files (AGENTS.md or kb/*.md files) to achieve the success criteria
3. Determine the current model from your system context (e.g., "opencode-go/glm-5" or "anthropic/claude-sonnet-4-5")
4. Run the test: `bash .opencode/commands/when-asked/opencode_run.sh "$1" <CURRENT_MODEL>`
5. Check the HTTP server log to verify which files were loaded: `grep "GET" .opencode/commands/when-asked/test-env/agents-http.log`
6. Analyze the test output and logs to determine if the success criteria was achieved
7. If not achieved, iterate: make more edits and re-run step 4
8. Continue until the agent achieves the success criteria without additional nudging
9. Stop the test environment when done: `bash .opencode/commands/when-asked/stop_env.sh`

**What to check:**
- HTTP logs should show GET requests to the relevant *.md files
- Test output should demonstrate the agent followed knowledge base instructions correctly
- No manual intervention or additional hints beyond the test task

**Test environment notes:**
- `prep_env.sh` creates test directory and starts HTTP server on port 8766
- `opencode_run.sh` clears HTTP log and runs opencode with isolated config
- `stop_env.sh` cleans up test directory and stops HTTP server
- Current model is extracted from system context and passed to opencode_run.sh
