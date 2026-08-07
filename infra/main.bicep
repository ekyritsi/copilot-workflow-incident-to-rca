targetScope = 'resourceGroup'

@description('Short application name used in Azure resource names.')
@minLength(5)
@maxLength(20)
param appName string = 'incident-demo'

@description('Azure region for the demo resources.')
param location string = resourceGroup().location

@description('Application Insights and Log Analytics retention in days.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

var normalizedName = toLower(replace(appName, '_', '-'))
var suffix = uniqueString(resourceGroup().id, normalizedName)
var workspaceName = '${normalizedName}-logs-${suffix}'
var insightsName = '${normalizedName}-ai-${suffix}'
var registryName = replace('${normalizedName}cr${suffix}', '-', '')
var environmentName = '${normalizedName}-env-${suffix}'
var containerAppName = '${normalizedName}-${suffix}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: workspaceName
  location: location
  tags: {
    demo: 'copilot-incident-to-rca'
    environment: 'demo'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: insightsName
  location: location
  kind: 'web'
  tags: {
    demo: 'copilot-incident-to-rca'
    environment: 'demo'
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
    RetentionInDays: retentionInDays
  }
}

resource registry 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: registryName
  location: location
  sku: {
    name: 'Basic'
  }
  tags: {
    demo: 'copilot-incident-to-rca'
    environment: 'demo'
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

resource environment 'Microsoft.App/managedEnvironments@2025-01-01' = {
  name: environmentName
  location: location
  tags: {
    demo: 'copilot-incident-to-rca'
    environment: 'demo'
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: workspace.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2025-01-01' = {
  name: containerAppName
  location: location
  tags: {
    demo: 'copilot-incident-to-rca'
    environment: 'demo'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: registry.properties.loginServer
          identity: 'System'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'incident-demo'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
            {
              name: 'DEMO_FAILURE_MODE'
              value: 'healthy'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
    }
  }
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, containerApp.id, 'acrpull')
  scope: registry
  properties: {
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    )
  }
}

output containerAppName string = containerApp.name
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output registryName string = registry.name
output registryLoginServer string = registry.properties.loginServer
output appInsightsName string = appInsights.name
output logAnalyticsWorkspaceName string = workspace.name
