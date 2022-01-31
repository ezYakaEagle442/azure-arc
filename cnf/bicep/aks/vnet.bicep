param vnetName string = 'vnet-aks'
param vnetCidr string = '172.16.0.0/16 '
param aksSubnetCidr string = '172.16.1.0/24'


var aksSubnet = {
  name: 'snet-aks'
  cidr: aksSubnetCidr
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
        name: aksSubnet.name
        properties: {
          addressPrefix: aksSubnet.cidr
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
output aksSubnetId string = vnet.properties.subnets[0].id
output aksSubnetAddressPrefix string = vnet.properties.subnets[0].properties.addressPrefix
