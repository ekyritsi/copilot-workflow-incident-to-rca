# Copilot Workflow: Incident to RCA

This repository is a repeatable demonstration of GitHub Copilot App as an incident command surface:

1. A web application starts returning errors.
2. Copilot correlates Azure telemetry with GitHub changes.
3. Copilot proposes and implements a fix through a pull request.
4. GitHub Actions deploys the approved fix.
5. Copilot verifies recovery.
6. Copilot creates an RCA and leadership briefing using M365.

The demo is intentionally small, resettable, and safe to run in a dedicated Azure resource group.

## What is included

| Path | Purpose |
| --- | --- |
| `src/server.js` | Node.js demo service. It serves the GitHub-styled status UI and API, exposes `/health`, supports a partial application regression scenario, and emits Application Insights telemetry. |
| `public/index.html` | Primer- and GitHub-brand-inspired status UI that probes every customer-facing API and makes partial outages visible. |
| `public/mona-single.png` | Single mascot artwork used by the status UI. |
| `test/server.test.js` | Verifies the documented API contracts. |
| `Dockerfile` | Packages the service as a small, non-root Node.js container for Container Apps. |
| `infra/main.bicep` | Declares the Azure resources required by the demo. |
| `infra/README.md` | Infrastructure-specific deployment and review guidance. |
| `scripts/seed-regression.sh` | Creates and pushes an intentional orders serialization regression branch and pull request so GitHub Actions deploys a realistic partial outage. |
| `scripts/configure-github-oidc.sh` | Creates the federated GitHub Actions identity and prints the GitHub Environment variables needed for deployment. |
| `.github/workflows/ci.yml` | Installs dependencies, checks JavaScript syntax, and runs tests. |
| `.github/workflows/deploy.yml` | Authenticates with Azure using OIDC, builds/pushes the image, updates the Container App, and runs a health smoke test. |
| `.github/workflows/codeql.yml` | Runs CodeQL analysis for JavaScript/TypeScript changes. |
| `.github/copilot-instructions.md` | Defines the investigation, approval, remediation, verification, and RCA guardrails for Copilot. |
| `.github/skills/incident-triage/SKILL.md` | Guides evidence-first correlation of Azure telemetry, GitHub changes, and deployments. |
| `.github/skills/rca/SKILL.md` | Guides evidence-backed RCA and leadership-summary generation. |
| `demo/prompts.md` | Reusable Copilot prompts for each stage of the workflow. |
| `demo/demo-script.md` | Presenter script for running the end-to-end demonstration. |
| `SECURITY.md` | Security, OIDC, environment protection, RBAC, and secret-handling guidance. |

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

## Azure resources

`infra/main.bicep` creates the following resources in the selected resource group. Names receive a deterministic suffix derived from that resource group, so another user deploying the same template gets their own resource names.

| Resource | Why it exists |
| --- | --- |
| Container Apps managed environment | Provides the managed runtime boundary for the demo Container App. |
| Container App | Runs the demo service with external HTTPS ingress and scale-to-zero behavior to reduce idle cost. |
| Azure Container Registry (Basic) | Stores the image built by GitHub Actions. Anonymous pulls and registry admin credentials are disabled. |
| Log Analytics workspace | Collects Container Apps platform and application logs for Copilot/Azure MCP investigation. |
| Workspace-based Application Insights | Collects requests, failures, exceptions, dependencies, and performance telemetry for incident diagnosis. |
| User-assigned managed identity | Lets GitHub Actions authenticate to Azure with OIDC and push the image without storing an Azure client secret. |
| Application Insights Smart Detection action group | Azure-created alert integration associated with Application Insights telemetry. It is retained with the active deployment. |

The Container App identity also receives `AcrPull` on the active registry. The GitHub Actions identity receives resource-group deployment access and `AcrPush`; this bootstrap scope is intentionally simple for a demo and should be narrowed before production use.

### Portability to another Azure subscription

Nothing in the application or Bicep template is tied to the original subscription or tenant. A new user should:

```bash
az login
az account set --subscription "<your-subscription-id>"
az group create --name "<your-resource-group>" --location eastus
az deployment group what-if \
  --resource-group "<your-resource-group>" \
  --template-file infra/main.bicep \
  --parameters appName=incident-demo
az deployment group create \
  --resource-group "<your-resource-group>" \
  --template-file infra/main.bicep \
  --parameters appName=incident-demo
```

Then configure the GitHub `demo` Environment using the values printed by `scripts/configure-github-oidc.sh`. The `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`, resource-group name, Container App name, registry name, and client ID are deployment-specific identifiers; they must be supplied by the person recreating the demo and must not be committed to the repository.

## Local run

```bash
npm install
npm test
npm start
```

Run `npm start`, then open <http://localhost:8080/> and <http://localhost:8080/health>.

To run the healthy app locally:

```bash
npm start
curl -i http://localhost:8080/health
```

The root endpoint renders a lightweight GitHub-styled status page. It probes `/health` and `/api/orders` in the browser, so a failing orders API makes the site visibly show an incident even when the root page and health endpoint remain available.

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

The deployment creates a scale-to-zero Container App (`minReplicas: 0`) and a Basic Container Registry. This avoids dedicated App Service VM quota and reduces idle compute cost. Because the app can scale to zero, the first refresh after inactivity may take several seconds while a replica starts; subsequent requests should be faster. Keep the resource group dedicated to this demo.

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

The workflow uses the `demo` Environment, so the OIDC federated credential must match that environment. The setup script supports deployment-specific `CONTAINER_APP_NAME`, `REGISTRY_NAME`, `RESOURCE_GROUP`, `SUBSCRIPTION_ID`, and `TENANT_ID` environment variables when the deployment output is not the default deployment name.

### Deploy the app

Push to `main` after the infrastructure exists. The `deploy.yml` workflow:

1. Runs tests.
2. Logs into Azure through OIDC.
3. Builds and pushes the image to Azure Container Registry.
4. Updates the Container App revision.
5. Runs a smoke test against `/health`.

## Demo flow

Read `demo/demo-script.md` for the presenter script and `demo/prompts.md` for prompts that make Copilot's evidence trail visible.

The incident is the GitHub-delivered partial regression. Set `GITHUB_REPOSITORY`, run `scripts/seed-regression.sh`, review and merge the generated pull request, and let GitHub Actions deploy it. The seeder automatically adds a UTC timestamp to the branch name when a previous run already used the default branch, so the demo can be repeated without manual branch cleanup. The landing page and `/health` remain available, while `/api/orders` returns HTTP 500. The UI probes both APIs, flips Mona upside down, and shows the failing endpoint. Copilot must correlate the failure with the merged commit and deployment, implement a code fix in a follow-up pull request, and let GitHub Actions deploy the remediation.

## Safety and governance

- Use a dedicated non-production resource group.
- Start with read-only Azure MCP operations.
- Require explicit approval before deployment.
- Do not commit Azure credentials, tokens, publish profiles, or tenant-specific secrets.
- Use synthetic data in the demo.
- Treat Azure and GitHub as the systems of record; Copilot is the orchestration surface.
- Add retention, budget, RBAC, and audit controls before using this pattern with a partner or customer.
