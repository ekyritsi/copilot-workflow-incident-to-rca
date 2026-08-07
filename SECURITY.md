# Security policy

This repository is a demonstration project and must be deployed only to a dedicated, non-production Azure resource group.

## Reporting a vulnerability

Do not open a public issue for a security vulnerability. Use the repository's private vulnerability reporting flow or contact the repository owners.

## Required controls

- Use GitHub Actions OIDC rather than stored Azure client secrets.
- Store non-secret deployment identifiers as GitHub Environment variables.
- Store any future credentials as GitHub Environment secrets.
- Protect the `demo` environment with required reviewers before enabling deployment.
- Restrict the deployment identity to the demo resource group.
- Review and reduce the bootstrap `Contributor` role before adapting this demo for production.
- Do not commit `.env` files, connection strings, publish profiles, tokens, or customer data.

