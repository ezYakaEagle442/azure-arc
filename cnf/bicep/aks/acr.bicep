@description('A UNIQUE name')
@maxLength(25)
param appName string = 'demo-101-${uniqueString(resourceGroup().id)}'

@description('The name of the ACR, must be UNIQUE')
param acrName string = 'acr-${appName}'

@description('The ACR location')
param location string = resourceGroup().location

// Specifies the IP or IP range in CIDR format. Only IPV4 address is allowed
@description('The AKS cluster CIDR')
param networkRuleSetCidr string


resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  /*
  identity: {
    principalId: 'string'
    tenantId: 'string'
    type: 'string'
    userAssignedIdentities: {}
  }
  */
  properties: {
    adminUserEnabled: false
    dataEndpointEnabled: true
    networkRuleSet: {
      defaultAction: 'Deny'
      ipRules: [
        {
          action: 'Allow'
          value: networkRuleSetCidr
        }
      ]
    }
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

output acrId string = acr.id
output acrIdentity string = acr.identity.principalId
