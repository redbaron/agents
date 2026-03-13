# GCP Gotchas

## Cloud SQL

- `gcloud sql instances patch --database-flags` REPLACES all flags, not merges.
  Always fetch existing flags first and include them in the patch command.
- `cloudsql.pg_authid_select_role` flag needed to read `pg_authid` (dynamic, no restart).
- Cloud SQL has no real PostgreSQL superuser (`rolsuper`). The closest is `cloudsqlsuperuser`
  (`rolcreaterole`, `rolcreatedb`, but not `rolsuper`).
- `gcloud sql users create` automatically grants `cloudsqlsuperuser` to every new user.
  To create a least-privilege user, do all setup first then `REVOKE cloudsqlsuperuser FROM <user>`.
- `gcloud sql users create` behaves as an upsert: if the user already exists it updates the
  password and returns success (exit 0).
- Labels update require `gcloud alpha sql instances patch --update-labels`.

### Backup & Restore vs Clone

`gcloud sql backups restore` restores data in-place into an existing instance.
`gcloud sql instances clone` requires deleting the target first — the new instance gets a new IP.

`gcloud sql backups restore` preserves instance-level metadata: IP addresses
(primary and private; outgoing may change), database flags, user labels, and
instance configuration (tier, disk, network, etc.).
