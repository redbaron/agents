# PostgreSQL Knowledge Base

## Logical Replication

### Publications

- `IN (...)` is NOT allowed in publication `WHERE` clauses — use `OR` chains instead.
- Dropping a publication owner user fails if the publication still exists — must `DROP PUBLICATION` first.

### Subscriptions

- `origin = 'none'` on both sides prevents replication loops in bidirectional setups.
- `copy_data = false` when source and target already have identical data (e.g. after clone).

### Replication Slots

- To drop an active replication slot: terminate the walsender and drop the slot in the same `psql` command
  (subscribers auto-reconnect, so a separate step risks the slot being reclaimed).

## COPY

### Performance: `COPY table` vs `COPY (SELECT * FROM table)`

- `COPY table TO` uses a plain single-backend sequential scan — no parallel workers, regardless of
  `max_parallel_workers_per_gather`. The code path (`src/backend/commands/copyto.c`, `cstate->rel`
  branch) calls `table_beginscan()` directly, bypassing the executor.
- `COPY (SELECT * FROM table) TO` goes through the planner/executor with `CURSOR_OPT_PARALLEL_OK`,
  so it **can** use parallel workers. This means the query form can be **faster** than the bare
  table form on large tables, despite looking equivalent.
- To maximize IO depth on high-latency storage (e.g. cloud disks), use the query form with
  `max_parallel_workers_per_gather` set appropriately.
