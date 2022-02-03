@description('A UNIQUE name')
@maxLength(25)
param appName string = 'demo-101-${uniqueString(resourceGroup().id)}'

@description('The name of the KV, must be UNIQUE')
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

@description('The AKS subnet ID, such as /subscriptions/subid/resourceGroups/rg-bicep/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/snet-aks')
param subnetID string


// https://en.wikipedia.org/wiki/ISO_8601#Durations
/* P is the duration designator (for period) placed at the start of the duration representation.
Y is the year designator that follows the value for the number of years.
M is the month designator that follows the value for the number of months.
W is the week designator that follows the value for the number of weeks.
D is the day designator that follows the value for the number of days.
*/
@description('KV The expiration time for the new key version. It should be in ISO8601 format. Eg: P90D, P1Y ')
param keyExpiryTime string = 'P90D'

@description('The time duration before key expiring to rotate or notify. It will be in ISO 8601 duration format. Eg: P90D, P1Y')
param lifetimeActionTriggerBeforeExpiry string = 'P7D'

// DateA: 30/06/2022  00:00:00
// DateB: 30/06/2022  00:00:00
// =(DateB-DateA)*24*60*60
@description('The AKS SSH Keys stoted in KV / Expiry date in seconds since 1970-01-01T00:00:00Z')
param aksSshKeyExpirationDate int = 1656547200

@description('the AKS cluster SSH key name')
param aksSshKeyName string = 'kv-ssh-keys-aks${appName}'

@description('Specifies all KV secrets {"secretName":"","secretValue":""} wrapped in a secure object.')
@secure()
param secretsObject object

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
    enableRbacAuthorization: true
    enablePurgeProtection: false
    enableSoftDelete: false
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
      virtualNetworkRules: [
        {
          id: subnetID
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
    softDeleteRetentionInDays: 30
  }
}
output vault object = kv

// Todo : create keys: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/keys?tabs=bicep
// https://docs.microsoft.com/en-us/azure/key-vault/keys/about-keys-details
resource kvKeys 'Microsoft.KeyVault/vaults/keys@2021-06-01-preview' = {
  name: aksSshKeyName
  parent: kv
  properties: {
    attributes: {
      enabled: true
      exp: aksSshKeyExpirationDate // Expiry date in seconds since 1970-01-01T00:00:00Z.
      exportable: false // Indicates if the private key can be exported. Exportable keys must have release policy.
      // nbf: int
    }
    keySize: 4096
    kty: 'RSA'
    rotationPolicy: {
      attributes: {
        expiryTime: keyExpiryTime
      }
      lifetimeActions: [
        {
          action: {
            type: 'notify'
          }
          trigger: { 
            // timeAfterCreate: 'string'
            timeBeforeExpiry: lifetimeActionTriggerBeforeExpiry
          }
        }
      ]
    }
    /*
    release_policy: {
      contentType: 'x'
      data: ''
    }
    */
  }
}

// See https://docs.microsoft.com/en-us/azure/developer/github/github-key-vault
// Todo : create secrets : https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets?tabs=bicep

resource kvSecrets 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = [for secret in secretsObject.secrets: {
  name: secret.secretName
  parent: kv
  properties: {
    attributes: {
      enabled: true
      exp: 1656547200
      // nbf: int
    }
    contentType: 'text/plain'
    value: secret.secretValue
  }
}]
