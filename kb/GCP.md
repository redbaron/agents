# GCP Gotchas

## Cloud SQL

- `gcloud sql instances patch --database-flags` REPLACES all flags, not merges.
  Always fetch existing flags first and include them in the patch command.
- `cloudsql.pg_authid_select_role` flag needed to read `pg_authid` (dynamic, no restart).
- `gcloud sql users create` grants `cloudsqlsuperuser` but NOT `REPLICATION` — must `ALTER ROLE`.
- `gcloud sql users create` behaves as an upsert: if the user already exists it updates the
  password and returns success (exit 0).
- Labels update require `gcloud alpha sql instances patch --update-labels`.

### Backup & Restore vs Clone

`gcloud sql backups restore` restores data in-place into an existing instance.
`gcloud sql instances clone` requires deleting the target first — the new instance gets a new IP.

`gcloud sql backups restore` preserves instance-level metadata: IP addresses
(primary and private; outgoing may change), database flags, user labels, and
instance configuration (tier, disk, network, etc.).
