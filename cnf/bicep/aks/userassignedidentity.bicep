
@description('A UNIQUE name')
@maxLength(25)
param appName string = 'demo-101-${uniqueString(deployment().name)}'

param location string = resourceGroup().location


resource azidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'id-${appName}'
  location: location
}

output identityid string = azidentity.id
output clientId string = azidentity.properties.clientId
output principalId string = azidentity.properties.principalId
