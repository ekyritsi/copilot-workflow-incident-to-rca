# Presenter script

## Setup

1. Show the healthy site and `/health` endpoint.
2. Show the repository and the deployment workflow.
3. Explain that the outage is seeded and reversible.

## Incident

1. Set `DEMO_FAILURE_MODE=outage` in the demo environment.
2. Show the site returning HTTP 503.
3. Ask Copilot to investigate without making changes.
4. Highlight the evidence trail: endpoint failures, timestamps, deployment/configuration history, and GitHub changes.

## Recovery

1. Ask Copilot for a remediation plan.
2. Approve the plan.
3. Have Copilot prepare the change as a pull request.
4. Let CI run tests and require approval before deployment.
5. Deploy the approved change.
6. Ask Copilot to verify recovery from both the user and telemetry perspectives.

## Organizational learning

1. Ask Copilot to create the RCA in M365.
2. Ask Copilot to create the LT deck.
3. End by showing that the same evidence became an operational fix, a durable record, and an executive communication.

