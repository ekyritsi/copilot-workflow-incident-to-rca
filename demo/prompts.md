# Demo prompts

Use these prompts in order. Replace placeholders with the actual resource group, app name, and URL.

## Triage

```text
The demo site is returning errors. Investigate the latest health and application signals in Azure for resource group rg-copilot-incident-demo. Start read-only. Tell me the incident window, affected endpoints, error rate, and the evidence supporting your conclusion.
```

```text
Correlate the Azure failure window with recent deployments, GitHub commits, pull requests, and Actions runs for this repository. Identify the most likely change and distinguish confirmed facts from hypotheses.
```

## Remediation

```text
Propose the lowest-risk fix. Include the exact change, tests, deployment plan, rollback plan, and risks. Do not modify files or deploy yet.
```

```text
Implement the approved fix in a branch, run the tests, and prepare a pull request. Do not deploy until I approve the pull request.
```

## Verification

```text
The fix has been deployed. Verify recovery using the app health endpoint, an end-user request, Azure metrics, and application logs. State what is verified and what remains uncertain.
```

## RCA and leadership communication

```text
Create an evidence-backed RCA for this incident using the investigation results and linked GitHub and Azure evidence. Include impact, timeline, root cause, mitigation, verification, and prevention actions with owners and due dates.
```

```text
Create a concise leadership deck from the RCA. Include business impact, customer symptoms, timeline, root cause in plain language, remediation, current status, and prevention commitments. Keep detailed technical evidence in an appendix.
```

