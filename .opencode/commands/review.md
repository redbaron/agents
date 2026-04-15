---
description: "Run a separate reviewer pass against the current work. Syntax: /review 'what to review'"
agent: review
---

Review the full set of changes on the current branch for correctness, regressions, hidden assumptions, and edge cases.

User request: $1

Review posture:
- prioritize findings over summaries
- focus on bugs and semantic mismatches, not style nits
- be suspicious of helpers or refactors that may hide meaningful differences between cases
- call out missing tests only when they materially increase risk

Start from the branch delta against its base branch unless the user request narrows the scope.
