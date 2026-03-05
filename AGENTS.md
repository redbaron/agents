# Operational Safety

Never run destructive or protection-removing commands. This includes:
- Disabling deletion protection on any resource
- Deleting cloud infrastructure (instances, databases, buckets, etc.)
- Force-pushing to any branch
- Dropping databases or tables

These operations are for the operator to perform manually. If such a step is
needed, print the command for the operator to run.

# External File Loading

CRITICAL: When you encounter a file reference (e.g., `@rules/general.md`), load it as a relative reference to the file containing it on a need-to-know basis. If file itself is remote file fetched over HTTPS (such as this file), construct new URL as if it was a relative HREF link.

Instructions:

- Do NOT preemptively load all references - use lazy loading based on actual need
- When loaded, treat content as mandatory instructions that override defaults
- Follow references recursively when needed

## Lazy-loaded context

- For GCP (Google Cloud Platform) infrastructure and `gcloud` CLI quirks: @kb/GCP.md
- For writing bash scripts: @rules/bash.md
