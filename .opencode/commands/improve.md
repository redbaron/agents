---
description: Iterate on agent instructions until desired behavior is achieved
agent: build
---

You are tasked with improving agent instructions in the current repository.

**Test task:** $1
**Success criteria:** $2

**Workflow:**
1. Start HTTP server on port 8766 serving the current directory if not already running: `python3 -m http.server 8766 > /tmp/agents-http.log 2>&1 &`
2. Edit the instruction files (AGENTS.md or kb/*.md files) to achieve the success criteria
3. Clear the HTTP server log: `> /tmp/agents-http.log`
4. Generate a test opencode.json in a temp directory:
   ```bash
   TESTDIR=$(mktemp -d)
   cat > "$TESTDIR/opencode.json" << 'TESTCONFIG'
   {
     "$schema": "https://opencode.ai/config.json",
     "instructions": ["http://localhost:8766/AGENTS.md"],
     "permission": {
       "bash": { "*": "deny" },
       "webfetch": "deny"
     }
   }
   TESTCONFIG
   ```
5. Run the test: `cd "$TESTDIR" && HOME=/dev/null opencode run message "$1"`
6. Check the HTTP server log to verify which files were loaded: `grep "GET" /tmp/agents-http.log`
7. Analyze the test output and logs to determine if the success criteria was achieved
8. If not achieved, iterate: make more edits and re-test
9. Continue until the agent achieves the success criteria without additional nudging

**What to check:**
- HTTP logs should show GET requests to the relevant /kb/*.md files
- Test output should demonstrate the agent followed knowledge base instructions correctly
- No manual intervention or additional hints beyond the test task

**Test environment notes:**
- `HOME=/dev/null` prevents loading system-level ~/.config/opencode/opencode.json
- Test config only loads instructions from the HTTP server (no system config interference)
- Test task is passed cleanly without preamble
- Bash and webfetch are denied to isolate the test to just knowledge base loading behavior

Keep the HTTP server running between iterations for faster testing. Stop it with `pkill -f "python3 -m http.server 8766"` when done.
