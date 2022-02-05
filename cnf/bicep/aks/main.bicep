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
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'iacdemo${uniqueString(resourceGroup().id)}'

param location string = 'northeurope'
// param rgName string = 'rg-${appName}'
param dnsPrefix string = 'appinnopinpin'
param acrName string = 'acr${appName}'
param clusterName string = 'aks-${appName}'
param aksVersion string = '1.22.4' //1.22 Alias in Preview
param MCnodeRG string = 'rg-MC-${appName}'
param logAnalyticsWorkspaceName string = 'log-${appName}'
param vnetName string = 'vnet-aks'
param subnetName string = 'snet-aks'
param vnetCidr string = '172.16.0.0/16'
param aksSubnetCidr string = '172.16.1.0/24'

@maxLength(24)
@description('The name of the KV, must be UNIQUE.  A vault name must be between 3-24 alphanumeric characters.')
param kvName string // = 'kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

param setKVAccessPolicies bool = false

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

/*
module rg 'rg.bicep' = {
  name: 'rg-bicep-${appName}'
  scope: subscription()
  params: {
    rgName: rgName
    location: location
  }
}
*/

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
}

module aksIdentity 'userassignedidentity.bicep' = {
  // scope: resourceGroup(rg.name)
  name: 'identity-aks-${appName}'
  params: {
    appName: appName
    location: location
  }  
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


var vNetRules = [
  {
    'id': vnet.outputs.aksSubnetId
    'ignoreMissingVnetServiceEndpoint': false
  }
]

// At this stage, must be configured: networkAcls/virtualNetworkRules to allow to AKS subnetID
module KeyVault '../kv/kv.bicep'= {
  name: kvName
  scope: resourceGroup(kvRGName)
  params: {
    location: location
    skuName: skuName
    tenantId: tenantId
    publicNetworkAccess: publicNetworkAccess
    vNetRules: vNetRules
    AKSIdentity: aksIdentity.outputs.principalId
    setKVAccessPolicies: true
  }
}

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  scope: resourceGroup(kvRGName)
  name: kvName
}

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scope-extension-resources
module roleAssignments 'roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    vnetName: vnetName
    subnetName: subnetName
    acrName: acrName
    kvName: kvName
    kvRGName: kvRGName
    aksPrincipalId: aksIdentity.outputs.principalId
    networkRoleType: 'NetworkContributor'
    acrRoleType: 'AcrPull'
    kvRoleType: 'KeyVaultReader'
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
    // kvAccessPolicies
  ]
}
