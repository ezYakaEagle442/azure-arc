param appName string = 'demo${uniqueString(resourceGroup().id)}'
param rgName string = 'rg-${appName}'
param dnsPrefix string = 'appinnopinpin'
param acrName string = 'acr${appName}'
param clusterName string = 'aks-${appName}'
param aksVersion string = '1.22' //1.22.4
param location string = 'northeurope'
param MCnodeRG string = 'rg-MC-${appName}'
param logAnalyticsWorkspaceName string = 'log-${appName}'

param vnetName string = 'vnet-aks'
param vnetCidr string = '172.16.0.0/16'
param aksSubnetCidr string = '172.16.1.0/24'

param sshPublicKey string
// ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/$ssh_key -C "youremail@groland.grd"
// Import your SSH keys to Azure KeyVault


module rg 'rg.bicep' = {
  name: 'rg-bicep'
  scope: subscription()
  params: {
    rgName: rgName
    location: location
  }
}

module loganalyticsworkspace 'log-analytics-workspace.bicep' = {
  name: 'log-bicep'
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
  dependsOn: [
    rg
  ]   
}

module vnet 'vnet.bicep' = {
  name: 'vnet-aks'
  // scope: resourceGroup(rg.name)
  params: {
     vnetName: vnetName
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
}

module acr 'acr.bicep' = {
  name: 'acr-bicep'
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    acrName: acrName
    location: location
    networkRuleSetCidr: vnet.outputs.aksSubnetAddressPrefix
  }
  dependsOn: [
    rg
  ]  
}

module roleAssignments 'roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    vnetId: vnet.outputs.vnetId
    acrId: acr.outputs.acrId
    aksPrincipalId: aksIdentity.outputs.principalId
    networkRoleType: 'NetworkContributor'
    acrRoleType: 'AcrPull'
  }
  dependsOn: [
    vnet
    acr
    aksIdentity
  ]  
}

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
    sshRSAPublicKey: sshPublicKey
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
