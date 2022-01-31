param vnetId string
param acrId string
param aksPrincipalId string

@allowed([
  'Owner'
  'Contributor'
  'NetworkContributor'
  'Reader'
])
@description('VNet Built-in role to assign')
param networkRoleType string

@allowed([
  'AcrPull'
  'AcrPush'
])
@description('ACR Built-in role to assign')
param acrRoleType string

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var role = {
  Owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
  NetworkContributor: '${vnetId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
  AcrPull: '${acrId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

// https://github.com/Azure/azure-quickstart-templates/blob/master/modules/Microsoft.ManagedIdentity/user-assigned-identity-role-assignment/1.0/main.bicep

// Assign ManagedIdentity ID to the "Network contributor" role
resource AKSClusterRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(vnetId, networkRoleType , aksPrincipalId)
  properties: {
    roleDefinitionId: role[networkRoleType] // subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: aksPrincipalId
    principalType: 'ServicePrincipal'
  }
}

 // acrpull role to assign to the AKS identity: az role assignment create --assignee $sp_id --role acrpull --scope $acr_registry_id
resource ACRRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(acrId, acrRoleType , aksPrincipalId)
  properties: {
    roleDefinitionId: role[acrRoleType]
    principalId: aksPrincipalId
    principalType: 'ServicePrincipal'
  }
}
