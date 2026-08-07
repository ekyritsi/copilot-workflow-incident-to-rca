# Infrastructure

`main.bicep` provisions the smallest useful Azure environment for this demo:

- Linux App Service plan
- Linux App Service
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

