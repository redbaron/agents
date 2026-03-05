# GCP Gotchas

## Cloud SQL

- `gcloud sql instances patch --database-flags` REPLACES all flags, not merges.
  Always fetch existing flags first and include them in the patch command.
