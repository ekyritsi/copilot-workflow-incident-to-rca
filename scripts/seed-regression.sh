#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPOSITORY:?Set GITHUB_REPOSITORY to owner/repository}"

repo_root="$(git rev-parse --show-toplevel)"
requested_branch="${1:-demo/orders-serialization-regression}"
branch="$requested_branch"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean. Commit or stash changes before seeding the regression." >&2
  exit 1
fi

branch_exists() {
  git show-ref --verify --quiet "refs/heads/$1" ||
    git ls-remote --exit-code --heads origin "$1" >/dev/null 2>&1
}

if branch_exists "$branch"; then
  suffix="$(date -u +%Y%m%d-%H%M%S)"
  branch="${requested_branch}-${suffix}"
  attempt=2
  while branch_exists "$branch"; do
    branch="${requested_branch}-${suffix}-${attempt}"
    attempt=$((attempt + 1))
  done
  echo "Branch already exists: $requested_branch" >&2
  echo "Using new branch: $branch" >&2
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
