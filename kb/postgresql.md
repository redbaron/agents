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

Verified against [REL_18_3](https://github.com/postgres/postgres/tree/REL_18_3).

- `COPY table TO` uses a plain single-backend sequential scan — no parallel workers, regardless of
  `max_parallel_workers_per_gather`. The code path calls [`table_beginscan()`][copyto-beginscan]
  directly, bypassing the executor.
- `COPY (SELECT * FROM table) TO` goes through the planner/executor with
  [`CURSOR_OPT_PARALLEL_OK`][copyto-parallel-ok], so it **can** use parallel workers. This means
  the query form can be **faster** than the bare table form on large tables, despite looking
  equivalent.
- To maximize IO depth on high-latency storage (e.g. cloud disks), use the query form with
  `max_parallel_workers_per_gather` set appropriately.
- **PG18+**: Both forms benefit from [ReadStream prefetching][heapam-readstream] (automatic
  look-ahead IO with AIO batching), set up transparently in `heap_beginscan()`. However, only the
  query form can use **multiple parallel workers**, each with its [own ReadStream][heapam-parallel-cb]
  reading different table regions — this provides both CPU and IO parallelism.

[copyto-beginscan]: https://github.com/postgres/postgres/blob/REL_18_3/src/backend/commands/copyto.c#L1071
[copyto-parallel-ok]: https://github.com/postgres/postgres/blob/REL_18_3/src/backend/commands/copyto.c#L799
[heapam-readstream]: https://github.com/postgres/postgres/blob/REL_18_3/src/backend/access/heap/heapam.c#L1196
[heapam-parallel-cb]: https://github.com/postgres/postgres/blob/REL_18_3/src/backend/access/heap/heapam.c#L250

### WHERE TRUE Trick for Logical Replication Initial Sync

- Creating a publication with `WHERE TRUE` forces the initial sync to use `COPY (SELECT ... WHERE true) TO`
  instead of `COPY table TO`. This enables parallel workers on the publisher side during initial data copy.
- The trick works because a non-null `prqual` in `pg_publication_rel` causes [`copy_table()`][tablesync-copy]
  to take the query-based COPY path, which goes through the executor with `CURSOR_OPT_PARALLEL_OK`.
- Only affects the **publisher side**. The subscriber is always single-threaded per table.

[tablesync-copy]: https://github.com/postgres/postgres/blob/REL_18_3/src/backend/replication/logical/tablesync.c#L1143

## psql CLI

- `:var` substitution does **not** work with `-c` — use `-f` or stdin instead.
