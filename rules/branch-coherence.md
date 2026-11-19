# Branch Coherence

## Maintain the Current Solution

- Treat each request as an update to the branch's overall goal. Before changing
  code, reconcile the request with the established intent and current design.

- When an iteration changes the approach, identify what it supersedes. Update
  or remove code paths, behaviors, contracts, configuration, tests, and
  documentation that existed to support the previous approach.

- Keep one coherent implementation of the current design. Retain parallel
  paths, fallbacks, compatibility layers, or abstractions only when they serve
  an identifiable requirement or an established consumer.

- Distinguish requirements from implementation history. A behavior introduced
  earlier in the branch needs a current justification to remain.

## Review the Affected Whole

- Before editing, inspect the relevant existing implementation and the branch
  changes that led to it. Follow affected callers and consumers far enough to
  understand the consequences of the proposed change.

- After a meaningful design change, review the cumulative branch diff for
  coherence. Look for superseded approaches, duplicated responsibilities,
  unused paths, stale assumptions, and contracts that no longer fit.

- Evaluate how the pieces work together as well as whether each changed piece
  is locally correct. Passing tests establish only the behaviors they exercise.

- Keep cleanup tied to the branch's goal and the consequences of its changes.
  Preserve unrelated work.

## Resolve Uncertain Obligations

- Before removing an existing behavior or compatibility contract, check for
  consumers and documented requirements. Treat established external contracts
  as obligations until evidence or an explicit decision permits changing them.

- When retaining something whose purpose is unclear, investigate its role.
  Ask a focused question when the answer would materially change the solution.

## Completion

- Before declaring the work complete, review the cumulative branch diff against
  the current goal, including changes inherited from earlier iterations.

- Remove superseded code and update affected tests and documentation. Report
  any remaining transitional behavior, its purpose, and what is needed to
  retire it.
