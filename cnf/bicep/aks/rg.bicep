targetScope = 'subscription'

@description('A UNIQUE name')
@maxLength(25)
param appName string = 'demo-101-${uniqueString(deployment().location)}'

param location string = deployment().location
param rgName string  = 'rg-${appName}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: rgName
}
output rgId string = rg.id
output rgName string = rg.name
