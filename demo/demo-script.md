# Presenter script

## Setup

1. Show the healthy site, `/health`, and `/api/orders` endpoints.
2. Show the repository and the deployment workflow.
3. Explain that the incident is introduced through a reviewed GitHub change and is reversible through a code fix.

## Incident

1. Run `GITHUB_REPOSITORY=github/copilot-workflow-incident-to-rca ./scripts/seed-regression.sh`.
2. Review and merge the generated pull request.
3. Let GitHub Actions deploy the new revision.
4. Refresh the landing page and show Mona upside down, the incident banner, and the API health cards identifying `/api/orders` as HTTP 500 while `/health` remains HTTP 200.
5. Ask Copilot to investigate without making changes.
6. Highlight the evidence trail: endpoint failures, timestamps, deployment revision, merged commit, and Actions run.

## Recovery

1. Ask Copilot for a remediation plan that changes application code rather than flipping a runtime mode.
2. Approve the plan.
3. Have Copilot prepare the change as a pull request.
4. Let CI run tests and require approval before deployment.
5. Deploy the approved change.
6. Ask Copilot to verify recovery from both the user and telemetry perspectives.

## Organizational learning

1. Ask Copilot to create the RCA in M365.
2. Ask Copilot to create the LT deck.
3. End by showing that the same evidence became an operational fix, a durable record, and an executive communication.
