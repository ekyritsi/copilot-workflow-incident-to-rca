targetScope = 'resourceGroup'

@description('Short application name used in Azure resource names.')
param appName string = 'incident-demo'

@description('Azure region for the demo resources.')
param location string = resourceGroup().location

@description('App Service pricing tier. B1 is inexpensive and supports a reliable live demo.')
param skuName string = 'B1'

@description('Application Insights and Log Analytics retention in days.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

var normalizedName = toLower(replace(appName, '_', '-'))
var suffix = uniqueString(resourceGroup().id, normalizedName)
var planName = '${normalizedName}-plan-${suffix}'
var webAppName = '${normalizedName}-${suffix}'
var workspaceName = '${normalizedName}-logs-${suffix}'
var insightsName = '${normalizedName}-ai-${suffix}'

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

resource plan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: planName
  location: location
  kind: 'linux'
  tags: {
    demo: 'copilot-incident-to-rca'
    environment: 'demo'
  }
  sku: {
    name: skuName
  }
  properties: {
    reserved: true
  }
}

resource site 'Microsoft.Web/sites@2024-11-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  tags: {
    demo: 'copilot-incident-to-rca'
    environment: 'demo'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'DEMO_FAILURE_MODE'
          value: 'healthy'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
  }
}

output webAppName string = site.name
output webAppUrl string = 'https://${site.properties.defaultHostName}'
output appInsightsName string = appInsights.name
output logAnalyticsWorkspaceName string = workspace.name
