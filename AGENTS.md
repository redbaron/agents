# Operational Safety

Never run destructive or protection-removing commands. This includes:
- Disabling deletion protection on any resource
- Deleting cloud infrastructure (instances, databases, buckets, etc.)
- Force-pushing to any branch
- Dropping databases or tables

These operations are for the operator to perform manually. If such a step is
needed, print the command for the operator to run.

# Lazy-loaded context

- For GCP infrastructure and `gcloud` CLI quirks load @kb/GCP.md
