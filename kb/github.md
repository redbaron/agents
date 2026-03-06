# GitHub CLI and API

## Fetching unresolved PR review comments

**Important**: Filtering by review ID alone does NOT exclude resolved comments. Use the GraphQL API to check thread resolution status.

Use this GraphQL query to get only unresolved, non-outdated comments:

```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: NUMBER) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          comments(first: 10) {
            nodes {
              author { login }
              body
              path
              line
            }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false and .isOutdated == false) | .comments.nodes[] | select(.author.login | contains("copilot")) | {path: .path, line: .line, body: .body}'
```

**Key fields**:
- `isResolved` - true if the review thread was marked as resolved
- `isOutdated` - true if the code changed and the comment is now outdated

**Note**: The REST API `/reviews/{review_id}/comments` endpoint returns ALL comments from that review, including resolved ones. Only the GraphQL API with `reviewThreads` provides resolution status.
