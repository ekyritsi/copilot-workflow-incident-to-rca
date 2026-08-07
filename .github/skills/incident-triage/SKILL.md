---
name: incident-triage
description: Correlate Azure health, logs, metrics, deployments, and GitHub changes for the incident-to-RCA demo.
---

# Incident triage

1. Establish the incident window from the user report and Azure telemetry.
2. Inspect application health, request failures, exceptions, dependency failures, and recent deployments.
3. Compare the failure window with GitHub commits, pull requests, and Actions runs.
4. Produce a short evidence table:
   - Signal
   - Observation
   - Time
   - Source
   - Interpretation
5. Separate confirmed facts from hypotheses.
6. Recommend the lowest-risk next diagnostic or remediation action.

Do not make changes during triage.

