// see BICEP samples at https://github.com/ssarwa/Bicep/blob/master/main.bicep
// https://github.com/brwilkinson/AzureDeploymentFramework/blob/main/ADF/bicep/AKS.bicep
@description('A UNIQUE name')
@maxLength(25)
param appName string = 'demo-101-${uniqueString(resourceGroup().id)}'

@description('The name of the Managed Cluster resource.')
param clusterName string = 'aks-${appName}'

// Preview: https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli#kubernetes-version-alias-preview
@description('The AKS Cluster alias version')
param k8sVersion string = '1.22' // 1.22.4

@description('The SubnetID to deploy the AKS Cluster')
param subnetID string

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string = 'appinno'

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

param identity object

@description('The Log Analytics workspace used by the OMS agent in the AKS Cluster')
param logAnalyticsWorkspaceId string 


@description('The number of nodes for the cluster.')
@minValue(1)
@maxValue(12)
param agentCount int = 3


@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_D2s_v3'

@description('User name for the Linux Virtual Machines.')
param linuxAdminUsername string = '${appName}-adm'

@description('Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
@secure()
param sshRSAPublicKey string

@description('The AKS cluster Managed ResourceGroup')
param nodeRG string = 'rg-MC-${appName}'


// https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/sshpublickeys?tabs=bicep
resource sshPublicKey 'Microsoft.Compute/sshPublicKeys@2021-07-01' = {
  name: 'sshpubkey'
  location: location
  properties: {
    // publicKey: 'string'
  }
}
output spk string = sshPublicKey.properties.publicKey

// https://docs.microsoft.com/en-us/azure/templates/microsoft.containerservice/managedclusters?tabs=bicep
resource aks 'Microsoft.ContainerService/managedClusters@2021-10-01' = {
  name: clusterName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Free'
  }    
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: identity
  } 
  properties: {
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        availabilityZones: [
          '1'
          '2'
          '3'
        ]        
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        enableAutoScaling: true
        count: agentCount
        minCount: 1        
        maxCount: 3
        maxPods: 30
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
        // spotMaxPrice: json('0.0229')
        vnetSubnetID: subnetID
        osSKU: 'CBLMariner'
      }  
    ]
    // see https://github.com/Azure/azure-rest-api-specs/issues/17563
    // https://github.com/brwilkinson/AzureDeploymentFramework/blob/main/ADF/bicep/AKS.bicep (main)
    // https://github.com/brwilkinson/AzureDeploymentFramework/blob/main/ADF/bicep/AKS-AKS.bicep
    // https://github.com/brwilkinson/AzureDeploymentFramework/blob/main/ADF/tenants/AOA/ACU1.T5.parameters.json#L985


    addonProfiles: {
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
        enabled: true
      }
      /*
      azurepolicy: {
        enabled: true
      }
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: appGatewayResourceId
          effectiveApplicationGatewayId: appGatewayResourceId
        }
      }
      */
      azureKeyvaultSecretsProvider: {
        enabled: true
      }      
    }
    nodeResourceGroup: nodeRG    
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
    } 
    kubernetesVersion: k8sVersion  
    networkProfile: {
      networkMode: 'transparent'
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      outboundType: 'loadBalancer'
      serviceCidr: '10.42.0.0/24'
      dnsServiceIP: '10.42.0.10'         
    }           
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshRSAPublicKey
          }
        ]
      }
    }
  }
}

output controlPlaneFQDN string = aks.properties.fqdn
output kubeletIdentity string = aks.properties.identityProfile.kubeletidentity.objectId
output ingressIdentity string = aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId
output keyvaultaddonIdentity string = aks.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId
// output managedIdentityPrincipalId string = aks.identity.principalId
output aksObjectId string = aks.id
