param vnetName string = 'vnet-aro'
param vnetCidr string = '172.32.0.0/21'
param masterSubnetCidr string = '172.32.1.0/24'
param workerSubnetCidr string = '172.32.2.0/24'

var masterSubnet = {
  name: 'master-subnet'
  cidr: masterSubnetCidr
}

var workerSubnet = {
  name: 'worker-subnet'
  cidr: workerSubnetCidr
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCidr
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: masterSubnet.name
        properties: {
          addressPrefix: masterSubnet.cidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
              locations: [
                '*'
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: workerSubnet.name
        properties: {
          addressPrefix: workerSubnet.cidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
              locations: [
                '*'
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

output vnetId string = vnet.id
output masterSubnetId string = vnet.properties.subnets[0].id
output workerSubnetId string = vnet.properties.subnets[1].id
