#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPOSITORY:?Set GITHUB_REPOSITORY to owner/repository}"

repo_root="$(git rev-parse --show-toplevel)"
branch="${1:-demo/orders-serialization-regression}"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean. Commit or stash changes before seeding the regression." >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "Branch already exists: $branch" >&2
  exit 1
fi

git switch -c "$branch"
git apply "$repo_root/demo/orders-serialization-regression.patch"
git add src/server.js
git commit -m "Introduce orders serialization regression for incident demo"
git push --set-upstream origin "$branch"

gh pr create \
  --repo "$GITHUB_REPOSITORY" \
  --base main \
  --head "$branch" \
  --title "Demo incident: orders serialization regression" \
  --body "This intentionally introduces a partial outage for the incident-to-RCA demonstration. The landing page and health endpoint remain available, while /api/orders emits 500 responses after deployment. Merge only for the demo, then remediate through a follow-up pull request."

echo "Regression branch and pull request created. Merge the PR to trigger GitHub Actions and deploy the incident."
