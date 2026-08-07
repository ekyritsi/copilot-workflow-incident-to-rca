# Incident-to-RCA demo instructions

This repository is a controlled demonstration environment. Treat Azure and GitHub as the systems of record.

## Investigation rules

- Start with read-only inspection.
- Correlate metrics, logs, deployment history, commits, and pull requests.
- State the evidence for each conclusion and identify unknowns.
- Do not change production settings or deploy without explicit user approval.
- Prefer a pull request and CI validation over direct edits.
- Never request, print, or commit credentials and secrets.

## Remediation rules

- Describe the proposed change, risk, test plan, and rollback plan before changing files.
- Run the smallest relevant tests.
- Verify the live health endpoint after deployment.
- Confirm recovery through both telemetry and an end-user request.

## RCA rules

When creating the RCA, use WorkIQ/M365 and the DOCX/Word skill to produce a formatted Word document (`.docx`), not only a chat response or Markdown file.

An RCA must include impact, customer symptoms, timeline, detection, root cause, contributing factors, mitigation, verification evidence, and prevention actions with owners and dates.
