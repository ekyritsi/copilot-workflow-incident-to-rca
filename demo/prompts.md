# Demo prompts

Use these prompts in order. Replace placeholders with the actual resource group, app name, and URL.

## Triage

```text
The demo site is returning errors. Investigate the latest health and application signals in Azure for resource group rg-copilot-incident-demo. Start read-only. Check both the site health endpoint and the business endpoint /api/orders. Tell me the incident window, affected endpoints, error rate, and the evidence supporting your conclusion.
```

```text
Correlate the Azure failure window with recent Container App revisions, GitHub commits, pull requests, and Actions runs for this repository. Focus on changes deployed immediately before the first /api/orders failures. Identify the most likely regression and distinguish confirmed facts from hypotheses. Do not change configuration or deploy anything.
```

## Remediation

```text
Propose the lowest-risk code fix for the orders regression. Include the exact file and change, tests for both /health and /api/orders, deployment plan, rollback plan, and risks. Do not modify files or deploy yet. The remediation must be a code change delivered through a pull request and GitHub Actions.
```

```text
Implement the approved fix in a branch, run the tests, and prepare a pull request. Do not deploy until I approve the pull request. The remediation must be delivered through the repository and GitHub Actions.
```

## Verification

```text
The fix has been deployed. Verify recovery using the app health endpoint, an end-user request, Azure metrics, and application logs. State what is verified and what remains uncertain.
```

## RCA and leadership communication

```text
Create an evidence-backed RCA as a Word document. Use the investigation results and linked GitHub and Azure evidence. Include impact, timeline, root cause, mitigation, verification, and prevention actions with owners and due dates.
```

```text
Create a concise leadership deck from the RCA. Include business impact, customer symptoms, timeline, root cause in plain language, remediation, current status, and prevention commitments. Keep detailed technical evidence in an appendix.
```
