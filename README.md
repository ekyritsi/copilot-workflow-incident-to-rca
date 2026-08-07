# Copilot Workflow: Incident to RCA

This repository is a repeatable demonstration of GitHub Copilot App as an incident command surface:

1. A web application starts returning errors.
2. Copilot correlates Azure telemetry with GitHub changes.
3. Copilot proposes and implements a fix through a pull request.
4. GitHub Actions deploys the approved fix.
5. Copilot verifies recovery.
6. Copilot creates an RCA and leadership briefing using M365.

The demo is intentionally small, resettable, and safe to run in a dedicated Azure resource group.

## Architecture

```text
GitHub repository
  |-- GitHub Actions ------------------------------+
  |                                                 |
  +-- Node.js demo app --> Azure Container Apps    |
                              |                    |
                              +--> Application Insights
                              |        |
                              +--> Log Analytics
                                                     |
Copilot App <--- Azure MCP Server ------------------+
     |
     +--- WorkIQ / M365: RCA, action items, executive deck
```

## Prerequisites

- Azure subscription and a dedicated resource group
- Azure CLI authenticated with `az login`
- Node.js 22 or later
- Docker Desktop or another Docker engine
- GitHub repository with Actions enabled
- Azure MCP Server configured in Copilot App
- Permissions to deploy to the demo resource group

## Local run

```bash
npm install
npm test
npm start
```

Run `npm start`, then open <http://localhost:8080/> and <http://localhost:8080/health>.

To reproduce an outage locally:

```bash
DEMO_FAILURE_MODE=outage npm start
curl -i http://localhost:8080/health
```

Supported failure modes:

- `healthy` (default): requests succeed.
- `outage`: health and application requests return HTTP 503.
- `exception`: application requests emit an exception and return HTTP 500.

## Azure deployment

The infrastructure is defined in `infra/main.bicep`. It creates:

- Azure Container Apps managed environment
- Azure Container App
- Basic Azure Container Registry
- Log Analytics workspace
- Workspace-based Application Insights

The application is deployed separately through GitHub Actions.

### Provision infrastructure

```bash
az deployment group what-if \
  --resource-group rg-copilot-incident-demo \
  --template-file infra/main.bicep \
  --parameters appName=incident-demo

az deployment group create \
  --resource-group rg-copilot-incident-demo \
  --template-file infra/main.bicep \
  --parameters appName=incident-demo
```

The deployment creates a scale-to-zero Container App and a Basic Container Registry. This avoids dedicated App Service VM quota and reduces idle compute cost. Keep the resource group dedicated to this demo.

### Configure GitHub Actions authentication

The recommended path is GitHub Actions OpenID Connect (OIDC), not a long-lived client secret or publish profile. After creating the GitHub repository, run:

```bash
./scripts/configure-github-oidc.sh <github-owner> <github-repository>
```

Follow the script output to add these GitHub repository variables:

- `AZURE_CLIENT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_TENANT_ID`
- `AZURE_RESOURCE_GROUP`
- `AZURE_CONTAINER_APP_NAME`
- `AZURE_ACR_NAME`

The bootstrap identity is scoped to the demo resource group for simplicity. Use a custom least-privilege deployment role before adapting this pattern for production.

The values above are identifiers, not credentials, so they belong in GitHub Environment **Variables**. OIDC means this workflow does not need an Azure client secret. If a future integration requires a credential, store it only as a GitHub Environment **Secret** and reference it through `${{ secrets.NAME }}`.

In repository settings, create an environment named `demo`, add the variables above, and configure required reviewers. This makes production-like deployment approval visible during the demo.

### Deploy the app

Push to `main` after the infrastructure exists. The `deploy.yml` workflow:

1. Runs tests.
2. Logs into Azure through OIDC.
3. Builds and pushes the image to Azure Container Registry.
4. Updates the Container App revision.
5. Runs a smoke test against `/health`.

## Demo flow

Read `demo/demo-script.md` for the presenter script and `demo/prompts.md` for prompts that make Copilot's evidence trail visible.

The outage is reproducible by changing the Container App environment variable `DEMO_FAILURE_MODE` to `outage`. The recovery path is to change it back to `healthy` through a reviewed pull request.

## Safety and governance

- Use a dedicated non-production resource group.
- Start with read-only Azure MCP operations.
- Require explicit approval before deployment.
- Do not commit Azure credentials, tokens, publish profiles, or tenant-specific secrets.
- Use synthetic data in the demo.
- Treat Azure and GitHub as the systems of record; Copilot is the orchestration surface.
- Add retention, budget, RBAC, and audit controls before using this pattern with a partner or customer.
