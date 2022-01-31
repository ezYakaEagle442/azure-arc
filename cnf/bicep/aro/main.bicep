param clientId string
param clientObjectId string
param clientSecret string
param aroRpObjectId string
param domain string
param pullSecret string
param clusterName string = 'aro-demo-101'

module vnet 'vnet.bicep' = {
  name: 'vnet-aro'
}

module vnetRoleAssignments 'roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    vnetId: vnet.outputs.vnetId
    clientObjectId: clientObjectId
    aroRpObjectId: aroRpObjectId
  }
  dependsOn: [
    vnet
  ]  
}

module aro 'aro.bicep' = {
  name: 'aro'
  params: {
    domain: domain
    masterSubnetId: vnet.outputs.masterSubnetId
    workerSubnetId: vnet.outputs.workerSubnetId
    clientId: clientId
    clientSecret: clientSecret
    pullSecret: pullSecret
    clusterName: clusterName
  }

  dependsOn: [
    vnetRoleAssignments
  ]
}
