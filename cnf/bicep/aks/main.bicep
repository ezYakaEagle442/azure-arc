// Bicep Templaytes availables at https://github.com/Azure/bicep/tree/main/docs/examples/2

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#uniquestring
// uniqueString: You provide parameter values that limit the scope of uniqueness for the result. You can specify whether the name is unique down to subscription, resource group, or deployment.
// The returned value isn't a random string, but rather the result of a hash function. The returned value is 13 characters long. It isn't globally unique

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#guid
//guid function: Returns a string value containing 36 characters, isn't globally unique
// Unique scoped to deployment for a resource group
// param appName string = 'demo${guid(resourceGroup().id, deployment().name)}'

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#newguid
// Returns a string value containing 36 characters in the format of a globally unique identifier. 
// /!\ This function can only be used in the default value for a parameter.

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-date#utcnow
// You can only use this function within an expression for the default value of a parameter.
@maxLength(20)
param appName string = 'demo${uniqueString(utcNow())}'

param location string = 'northeurope'
param rgName string = 'rg-${appName}'
param dnsPrefix string = 'appinnopinpin'
param acrName string = 'acr${appName}'
param clusterName string = 'aks-${appName}'
param kvName string = 'kv-${appName}'
param aksVersion string = '1.22.4' //1.22 Alias in Preview
param MCnodeRG string = 'rg-MC-${appName}'
param logAnalyticsWorkspaceName string = 'log-${appName}'
param vnetName string = 'vnet-aks'
param subnetName string = 'snet-aks'
param vnetCidr string = '172.16.0.0/16'
param aksSubnetCidr string = '172.16.1.0/24'

@description('KV : The object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies.')
param objectId string 

@description('KV : Application ID of the AKS client making request on behalf of a principal')
param applicationId string 

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

@description('Is KV Network access public ?')
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'

@description('Specifies all KV secrets {"secretName":"","secretValue":""} wrapped in a secure object.')
@secure()
param secretsObject object

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

// param sshPublicKey string
// ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/$ssh_key -C "youremail@groland.grd"


module rg 'rg.bicep' = {
  name: 'rg-bicep-${appName}'
  scope: subscription()
  params: {
    rgName: rgName
    location: location
  }
}

module loganalyticsworkspace 'log-analytics-workspace.bicep' = {
  name: logAnalyticsWorkspaceName
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  } 
}

module vnet 'vnet.bicep' = {
  name: 'vnet-aks'
  // scope: resourceGroup(rg.name)
  params: {
     vnetName: vnetName
     aksSubnetName: subnetName
     vnetCidr: vnetCidr
     aksSubnetCidr: aksSubnetCidr
  }
  dependsOn: [
    rg
  ]    
}

module aksIdentity 'userassignedidentity.bicep' = {
  // scope: resourceGroup(rg.name)
  name: 'identity-aks-${appName}'
  params: {
    appName: appName
    location: location
  }
  dependsOn: [
    rg
  ]    
}

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    dataEndpointEnabled: false // data endpoint rule is not supported for the SKU Basic
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

module kvModule 'kv.bicep' = {
  name: kvName
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    location: location
    kvName: kvName
    tenantId: tenantId
    skuName: 'standard'
    subnetID: vnet.outputs.aksSubnetId
    publicNetworkAccess: publicNetworkAccess
    secretsObject: secretsObject
    aksSshKeyExpirationDate: aksSshKeyExpirationDate
    keyExpiryTime: keyExpiryTime
    lifetimeActionTriggerBeforeExpiry: lifetimeActionTriggerBeforeExpiry
    aksSshKeyName: aksSshKeyName
  }
}

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: kvName
  // scope: resourceGroup('Secret')
}

module roleAssignments 'roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    vnetId: vnet.outputs.vnetId
    vnetName: vnetName
    subnetName: subnetName
    acrName: acrName
    acrId: acr.id
    kvId: kv.id
    kvName: kvName
    aksPrincipalId: aksIdentity.outputs.principalId
    networkRoleType: 'NetworkContributor'
    acrRoleType: 'AcrPull'
    kvRoleType: 'KeyVaultAdministrator'
  }
}



// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/key-vault-parameter?tabs=azure-cli
/*
The user who deploys the Bicep file must have the Microsoft.KeyVault/vaults/deploy/action permission for the scope 
of the resource group and key vault. 
The Owner and Contributor roles both grant this access.
If you created the key vault, you're the owner and have the permission.
*/

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-secrets
module aks 'aks.bicep' = {
  name: 'aks'
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    clusterName: clusterName
    k8sVersion: aksVersion
    location: location
    nodeRG:MCnodeRG
    subnetID: vnet.outputs.aksSubnetId
    dnsPrefix: dnsPrefix
    sshRSAPublicKey: kv.getSecret('sshPublicKey')
    logAnalyticsWorkspaceId: loganalyticsworkspace.outputs.logAnalyticsWorkspaceId
    identity: {
      '${aksIdentity.outputs.identityid}' : {}
    }
  }
  dependsOn: [
    roleAssignments
  ]
}

// TODO : from Pipeline get aksIdentity objectId
// https://codingwithtaz.blog/2021/09/08/azure-pipelines-deploy-aks-with-bicep/
// create accessPolicies https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/accesspolicies?tabs=bicep
// /!\ Preview feature: When enableRbacAuthorization is true in KV, the key vault will use RBAC for authorization of data actions, and the access policies specified in vault properties will be ignored
resource kvAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: 'add'
  parent: kv
  properties: {
    accessPolicies: [
      {
        // applicationId: applicationId
        objectId: aksIdentity.outputs.principalId
        tenantId: tenantId
        permissions: {
          certificates: [
            'list'
            'get'
            'getissuers'
            'recover'
            'restore'
          ]
          keys: [
            'backup'
            'create'
            'decrypt'
            'delete'
            'encrypt'
            'get'
            'getrotationpolicy'
            'import'
            'list'
            'purge'
            'recover'
            'restore'
            'rotate'
            'setrotationpolicy'
            'sign'
            'update'
            'verify'
          ]
          secrets: [
            'all'
          ]
          storage: [
          ]
        }
      }
    ]
  }
}
