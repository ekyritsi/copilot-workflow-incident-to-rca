# Infrastructure

`main.bicep` provisions the smallest useful Azure environment for this demo:

- Azure Container Apps managed environment
- Azure Container App with scale-to-zero
- Basic Azure Container Registry
- Workspace-based Application Insights
- Log Analytics workspace

The template is scoped to a resource group and uses a deterministic suffix so it can be deployed repeatedly without collisions.

Before deployment:

```bash
az deployment group what-if \
  --resource-group rg-copilot-incident-demo \
  --template-file infra/main.bicep \
  --parameters appName=incident-demo
```

The resource group should remain dedicated to the demo. Review the generated plan before creating resources.

## Resource map

| Resource | Purpose |
| --- | --- |
| Container Apps managed environment | Hosts the managed Container App runtime. |
| Container App | Runs the demo service, exposes HTTPS ingress on port 8080, and scales from zero to one replica. |
| Basic Container Registry | Stores private demo images for GitHub Actions deployments. |
| Log Analytics workspace | Receives Container Apps logs. |
| Workspace-based Application Insights | Receives application telemetry and supports incident investigation. |

The template does not contain a subscription ID, tenant ID, credential, or customer-specific identifier. Azure generates the resource suffix from the target resource group ID.

The registry binding and `AcrPull` permission are applied after the initial Container App creation. This keeps infrastructure provisioning independent from container image availability; the deployment workflow configures the managed-identity registry binding before deploying the private image.
