param appName string = 'demo-101-${uniqueString(resourceGroup().id)}'

param logAnalyticsWorkspaceName string = 'log-${appName}'
param location string = 'northeurope'

// https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?tabs=bicep
resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
