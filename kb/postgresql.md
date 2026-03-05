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
