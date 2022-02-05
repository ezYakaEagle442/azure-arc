/*
If you need to purge KV: https://docs.microsoft.com/en-us/azure/key-vault/general/key-vault-recovery?tabs=azure-portal
The user will need the following permissions (at subscription level) to perform operations on soft-deleted vaults:
Microsoft.KeyVault/locations/deletedVaults/purge/action
*/

// https://argonsys.com/microsoft-cloud/library/dealing-with-deployment-blockers-with-bicep/

@description('A UNIQUE name')
@maxLength(20)
param appName string = 'iacdemo${uniqueString(resourceGroup().id)}'

@maxLength(24)
@description('The name of the KV, must be UNIQUE.  A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

@description('The KV location')
param location string = resourceGroup().location

@description('Is KV Network access public ?')
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'

@description('The KV SKU name')
@allowed([
  'premium'
  'standard'
])
param skuName string = 'standard'

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

@description('The KV vNetRules')
param vNetRules array = []

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenantId
    publicNetworkAccess: publicNetworkAccess
    enabledForDeployment: false // Property to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.
    enabledForDiskEncryption: true // When enabledForDiskEncryption is true, networkAcls.bypass must include \"AzureServices\
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableSoftDelete: true
    enableRbacAuthorization: false // /!\ Preview feature: When true, the key vault will use RBAC for authorization of data actions, and the access policies specified in vault properties will be ignored
    // When enabledForDeployment is true, networkAcls.bypass must include \"AzureServices\"
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      /*
      ipRules: [
        {
          value: 'string'
        }
      ]
      */
      virtualNetworkRules: vNetRules
    }
    softDeleteRetentionInDays: 7 // 30 must be greater or equal than '7' but less or equal than '90'.
    accessPolicies: []
  }
}
