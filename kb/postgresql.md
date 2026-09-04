# PostgreSQL Knowledge Base

## Logical Replication

### Publications

- `IN (...)` is NOT allowed in publication `WHERE` clauses — use `OR` chains instead.
- Dropping a publication owner user fails if the publication still exists — must `DROP PUBLICATION` first.

- Logical decoding uses **historic catalog snapshots** — publication membership and row
  filters are evaluated against catalog state as of the decoded WAL record, not current.
- If a publication doesn't exist at the slot's current WAL position, `pgoutput` logs
  `skipped loading publication "<name>"` and the slot advances **without applying changes**.
  `confirmed_flush_lsn` moves forward (lag shrinks) while no data is applied.
- `pg_copy_logical_replication_slot` copies the source slot's current LSN — cannot move
  backward.

### Subscriptions

- `origin = 'none'` on both sides prevents replication loops in bidirectional setups.
- `copy_data = false` when source and target already have identical data (e.g. after clone).

### Replication Slots

- To drop an active replication slot: terminate the walsender and drop the slot in the same `psql` command
  (subscribers auto-reconnect, so a separate step risks the slot being reclaimed).
- `restart_lsn` retains WAL; it is not an MVCC horizon.
- A normal logical slot typically has `catalog_xmin` but `xmin IS NULL`.
  Logical decoding reads row changes from WAL and uses historic catalog state to
  interpret them. It does not retain ordinary publisher heap versions.
- `copy_data = true` creates permanent per-table sync slots named
  `pg_<suboid>_sync_<pid>_<xid>` on the publisher. During initial COPY, the
  source transaction holds the consistent data snapshot; the slot can show
  `active = false` and `xmin IS NULL`.

### Monitoring tablesync progress

- `SELECT * FROM pg_stat_progress_copy` shows the actual COPY progress (rows copied, total rows) for the active tablesync worker.

## MVCC Cleanup Horizons

- A non-NULL data `xmin` retains heap versions that could be visible to that
  snapshot. It constrains VACUUM removal, opportunistic heap pruning, and btree
  `LP_DEAD` hints. `catalog_xmin` has the equivalent effect only for catalogs
  and shared relations.
- Initial logical table sync retains ordinary-table versions through the
  publisher COPY backend's `backend_xmin`, not through the sync slot's
  persisted `xmin`. Find source-side holders with:

  ```sql
  SELECT pid, backend_type, application_name, backend_xmin, xact_start, query
  FROM pg_stat_activity
  WHERE backend_xmin IS NOT NULL
  ORDER BY backend_xmin, xact_start;
  ```

- A physical slot by itself retains WAL through `restart_lsn`. It acquires a
  data `xmin` only from hot-standby feedback; while that feedback is retained,
  primary cleanup waits for standby snapshots. Without feedback, replay
  cancels conflicting standby queries instead.

## Parallel Worker Limits

- `max_parallel_workers` limits only dynamic workers marked
  `BGWORKER_CLASS_PARALLEL`: parallel query workers, parallel `VACUUM` index
  workers, and parallel B-tree, GIN, and BRIN index-build workers.
- Every running parallel worker also consumes one `max_worker_processes` slot.
  `max_parallel_workers` is not a reservation, so other background workers can
  leave fewer slots available for parallel work.
- Logical replication launcher, apply, parallel-apply, and table-sync workers
  consume `max_worker_processes` slots but not `max_parallel_workers`. The same
  is generally true for extension background workers.
- Autovacuum does not launch parallel index-vacuum workers; it sets
  `VacuumParams.nworkers = -1` and processes indexes serially.

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

## Replication Lag Monitoring

### What `pg_stat_replication` lag columns measure

- `write_lag`, `flush_lag`, `replay_lag` measure the time between the
  **walsender processing** an LSN and the standby/subscriber confirming that LSN.
  The timestamp paired with each LSN is `GetCurrentTimestamp()` at walsender
  processing time, not the time the WAL was originally generated. Both physical
  and logical replication use the same mechanism.
- `(pg_current_wal_lsn() - replay_lsn)::bigint` gives byte distance from the
  WAL tip to the replica's confirmed position. This is always accurate but is
  in bytes, not time.
- When replication is caught up, the time lag columns approximate data freshness.
  When there is a large backlog, they can show seconds while the replica is
  hours or days behind.

### What `pg_last_xact_replay_timestamp()` measures

Returns the **publisher's original commit timestamp** from the WAL record (the
primary's clock at commit time). Only works on physical standbys (servers in
recovery). Returns NULL on normal servers, including logical replication
subscribers. No configuration needed.

### What `pg_last_committed_xact()` returns

Returns `(xid, timestamp, roident)` for the globally latest committed
transaction. When `track_commit_timestamp = on` on the subscriber, the timestamp
for replicated transactions is the **publisher's** original commit time, not the
local apply time. `roident <> 0` indicates a replicated transaction. If the
subscriber has local writes, the latest xid may not be a replicated one.

### `track_commit_timestamp` GUC

Default `off`. Requires restart (`PGC_POSTMASTER`). Only needs to be on the
subscriber — the publisher always sends commit timestamps in the replication
protocol. Stores 10 bytes per unfrozen transaction on disk under `pg_commit_ts/`.
Entries are truncated by vacuum at the same time as CLOG.

### What `pg_stat_subscription` timestamps are

- `last_msg_send_time` — walsender's clock when it sent the WAL data message
- `last_msg_receipt_time` — subscriber's local clock when it received the message
- `latest_end_time` — walsender's timestamp from the last keepalive message

These are protocol-level timestamps. None are the publisher's original transaction
commit timestamp.

### `pg_replication_origin_status` has no timestamps

Exposes `remote_lsn` and `local_lsn` only. No LSN-to-xid conversion function
exists in PostgreSQL.

## psql CLI

- `:var` substitution does **not** work with `-c` — use `-f` or stdin instead.
