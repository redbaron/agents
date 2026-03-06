---
description: Iterate on agent instructions until desired behavior is achieved
agent: build
---

You are tasked with improving agent instructions in the current repository.

**Goal:** $ARGUMENTS

**Workflow:**
1. Start HTTP server on port 8766 serving the current directory if not already running: `python3 -m http.server 8766 > /tmp/agents-http.log 2>&1 &`
2. Edit the instruction files (AGENTS.md or kb/*.md files) to achieve the goal
3. Clear the HTTP server log: `> /tmp/agents-http.log`
4. Run a test with: `cd $(mktemp -d) && opencode run message "Load your instructions from http://localhost:8766/AGENTS.md

$ARGUMENTS"`
5. Check the HTTP server log to verify which files were loaded: `grep "GET" /tmp/agents-http.log`
6. Analyze the test output and logs to determine if the desired behavior was achieved
7. If not achieved, iterate: make more edits and re-test
8. Continue until the agent loads the correct knowledge bases and follows their instructions without additional nudging

**Success criteria:**
- The test agent loads all relevant knowledge base files (check HTTP logs for GET requests to /kb/*.md files)
- The test agent follows the instructions in those knowledge bases correctly
- No manual intervention or additional hints beyond the original task description

Keep the HTTP server running between iterations for faster testing. Stop it with `pkill -f "python3 -m http.server 8766"` when done.
