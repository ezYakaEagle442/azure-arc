// Bicep Templaytes availables at https://github.com/Azure/bicep/tree/main/docs/examples/2
param appName string = 'demo${uniqueString(resourceGroup().id)}'
param location string = 'northeurope'
param rgName string = 'rg-${appName}'
param dnsPrefix string = 'appinnopinpin'
param acrName string = 'acr${appName}'
param clusterName string = 'aks-${appName}'
param kvName string = 'kv${appName}'
param aksVersion string = '1.22' //1.22.4
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

param sshPublicKey string
// ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/$ssh_key -C "youremail@groland.grd"

@description('Specifies all KV secrets {"secretName":"","secretValue":""} wrapped in a secure object.')
@secure()
param secretsObject object

module rg 'rg.bicep' = {
  name: 'rg-bicep'
  scope: subscription()
  params: {
    rgName: rgName
    location: location
  }
}

module loganalyticsworkspace 'log-analytics-workspace.bicep' = {
  name: 'log'
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
  name: 'aksIdentity'
  params: {
    appName: appName
    location: location
  }
  dependsOn: [
    rg
  ]    
}

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: 'acr'
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
  name: 'kv'
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    location: location
    kvName: kvName
    skuName: 'standard'
    subnetID: vnet.outputs.aksSubnetId
    publicNetworkAccess: publicNetworkAccess
    secretsObject: secretsObject
  }
}

module roleAssignments 'roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    vnetId: vnet.outputs.vnetId
    vnetName: vnetName
    subnetName: subnetName
    acrName: acrName
    acrId: acr.id
    aksPrincipalId: aksIdentity.outputs.principalId
    networkRoleType: 'NetworkContributor'
    acrRoleType: 'AcrPull'
  }
}

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: kvName
  // scope: resourceGroup('Secret')
}

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
    sshRSAPublicKey: kv.getSecret('sshPublicKey') // sshPublicKey
    logAnalyticsWorkspaceId: loganalyticsworkspace.outputs.logAnalyticsWorkspaceId
    identity: {
      '${aksIdentity.outputs.identityid}' : {}
    }
  }
  dependsOn: [
    roleAssignments
    loganalyticsworkspace
  ]
}

// TODO : from Pipeline get aksIdentity objectId
// https://codingwithtaz.blog/2021/09/08/azure-pipelines-deploy-aks-with-bicep/
// Todo : create accessPolicies https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/accesspolicies?tabs=bicep
resource kvAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: 'add'
  parent: kv // resourceId('Microsoft.KeyVault/vaults', kvName)
  properties: {
    accessPolicies: [
      {
        // applicationId: applicationId
        objectId: aks.outputs.aksObjectId
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
