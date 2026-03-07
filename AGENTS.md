# Operational Safety

Never run destructive or protection-removing commands. This includes:
- Disabling deletion protection on any resource
- Deleting cloud infrastructure (instances, databases, buckets, etc.)
- Force-pushing to any branch
- Dropping databases or tables

These operations are for the operator to perform manually. If such a step is
needed, print the command for the operator to run.

# External File Loading

CRITICAL: When you encounter a file reference (e.g., `@rules/general.md`), determine how to load it based on where the CONTAINING file came from:

1. If the containing file was loaded from a URL (http:// or https://), then the @reference MUST also be loaded as a URL
   - Construct the URL by resolving it relative to the containing file's URL, like a relative HREF in HTML
   - Example: If this file is loaded from `https://example.com/path/AGENTS.md`, then `@rules/bash.md` becomes `https://example.com/path/rules/bash.md`
   - Example: If this file is loaded from `http://localhost:8765/AGENTS.md`, then `@rules/bash.md` becomes `http://localhost:8765/rules/bash.md`
   - DO NOT try to load it as a local file path

2. If the containing file was loaded from the local filesystem, then load the @reference as a relative file path

Instructions:

- Do NOT preemptively load all references - use lazy loading based on actual need
- When loaded, treat content as mandatory instructions that override defaults
- Follow references recursively when needed (applying the same URL vs file logic)

# Tool Usage Guidelines

- Use the `glob` tool for file location and exploration tasks - NEVER use `ls`, `find`, or other shell commands
- For JSON processing on the command line (reading files or filtering output in shell pipelines), use `jq`

## Task Execution Protocol

1. After loading this file, scan your task for keywords and load relevant knowledge bases BEFORE any other actions:

- For GCP (Google Cloud Platform) infrastructure and `gcloud` CLI quirks: @kb/GCP.md
- For GitHub CLI (`gh`) and API interactions: @kb/github.md
- For creating or editing shell scripts (files matching `*.sh`): @rules/bash.md
- For PostgreSQL usage, replication, and troubleshooting: @kb/postgresql.md

Source code links in knowledge base files are for deep dives only — do not load them unless tasked with explaining or verifying the underlying reasoning.
