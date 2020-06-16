Regarding ACR :
- [https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration#create-a-new-aks-cluster-with-acr-integration](https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration#create-a-new-aks-cluster-with-acr-integration)
- [https://github.com/Azure/azure-quickstart-templates/tree/master/101-aks](https://github.com/Azure/azure-quickstart-templates/tree/master/101-aks)


## pre-requisites
```sh
az extension list-available
# az extension remove --name aks-preview
az extension add --name aks-preview
az extension update --name aks-preview

# https://docs.microsoft.com/en-us/azure/governance/policy/concepts/rego-for-aks
# Provider register: Register the Azure Kubernetes Services provider
az provider register --namespace Microsoft.ContainerService

# Provider register: Register the Azure Policy provider
az provider register --namespace Microsoft.PolicyInsights

# Feature register: enables installing the add-on
az feature register --namespace Microsoft.ContainerService --name AKS-AzurePolicyAutoApprove

# Use the following to confirm the feature has registered
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzurePolicyAutoApprove')].{Name:name,State:properties.state}"

# Feature register: enables the add-on to call the Azure Policy resource provider
az feature register --namespace Microsoft.PolicyInsights --name AKS-DataPlaneAutoApprove

# Use the following to confirm the feature has registered
az feature list -o table --query "[?contains(name, 'Microsoft.PolicyInsights/AKS-DataPlaneAutoApprove')].{Name:name,State:properties.state}"

# Once the above shows 'Registered' run the following to propagate the update
az provider register -n Microsoft.PolicyInsights
# az provider unregister  -n Microsoft.PolicyInsights

az extension show --name aks-preview --query [version]

# ManagedIdentity requires aks-preview 0.4.38
az extension update --name aks-preview

```

## Create ACR
```sh
az provider register --namespace Microsoft.ContainerRegistry
az acr create --name $acr_registry_name --sku Standard --location $location -g $aks_rg_name

az acr repository list --name $acr_registry_name
az acr check-health --yes -n $acr_registry_name 

# Get the ACR registry resource id
acr_registry_id=$(az acr show --name $acr_registry_name --resource-group $rg_name --query "id" --output tsv)
echo "ACR registry ID :" $acr_registry_id

# with SP when Managed Identities is not set during AKS cluster creation : az role assignment create --assignee $sp_id --role acrpull --scope $acr_registry_id
#  when Managed Identities is set during AKS cluster creation :

CLIENT_ID=$(az aks show --resource-group $rg_name --name $cluster_name --query "servicePrincipalProfile.clientId" --output tsv)
echo "AKS CLIENT_ID:" $CLIENT_ID 

# aks_client_id=$(az aks show -g $rg_name -n $cluster_name --query identityProfile.kubeletidentity.clientId -o tsv)
# echo "AKS Cluster Identity Client ID " $aks_client_id

```


## Create AKS Cluster

To learn more about UDR, see [https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)


```sh

az aks create --name $aks_aks_cluster_name \
    --resource-group $aks_rg_name \
    --node-count 1 \
    --location $location \
    --vnet-subnet-id $aks_subnet_id \
    --service-cidr 10.42.0.0/24 \
    --dns-service-ip 10.42.0.10 \
    --kubernetes-version $aks_version \
    --network-plugin $aks_network_plugin \
    --network-policy $aks_network_policy \
    --nodepool-name $aks_node_pool_name \
    --admin-username $aks_admin_username \
    --load-balancer-sku standard \
    --vm-set-type VirtualMachineScaleSets \
    --ssh-key-value ~/.ssh/${ssh_key}.pub \
    --outbound-type loadBalancer \
    --service-principal $sp_id \
    --client-secret $sp_password \
    --attach-acr $acr_registry_name \
    --verbose

```


### Get AKS Credentials

Apply [k alias](./tools#kube-tools)

```sh

ls -al ~/.kube
rm  ~/.kube/config

az aks get-credentials --resource-group $aks_rg_name --name $aks_cluster_name --admin

az aks show -n $aks_cluster_name -g $aks_rg_name

aks_api_server_url=$(az aks show -n $aks_cluster_name -g $aks_rg_name --query 'privateFqdn' -o tsv)
echo "AKS API server URL: " $aks_api_server_url

```


## Connect to the Cluster

- install the [tools](tools.md)
- reinit your variables

```sh

az aks list -o table

aks_cluster_id=$(az aks show -n $aks_cluster_name -g $aks_rg_name --query id -o tsv)
echo "AKS cluster ID : " $aks_cluster_id

az aks get-credentials --resource-group $aks_rg_name --name $aks_cluster_name --admin
k cluster-info
k config view

# below is N/A with ManagedIdentities
# Get the id of the service principal configured for AKS
# CLIENT_ID=$(az aks show --resource-group $aks_rg_name --name $aks_cluster_name --query "servicePrincipalProfile.clientId" --output tsv)
# echo "CLIENT_ID:" $CLIENT_ID 


```

## Create Namespaces
```sh
k create namespace development
k label namespace/development purpose=development

k create namespace staging
k label namespace/staging purpose=staging

k create namespace production
k label namespace/production purpose=production

k create namespace sre
k label namespace/sre purpose=sre

k get namespaces
k describe namespace production
k describe namespace sre
```


## Optionnal Play: what resources are in your cluster

```sh
k get nodes

# https://docs.microsoft.com/en-us/azure/aks/availability-zones#verify-node-distribution-across-zones
# https://docs.microsoft.com/en-us/azure/aks/availability-zones#verify-pod-distribution-across-zones
k describe nodes | grep -e "Name:" -e "failure-domain.beta.kubernetes.io/zone"

k get pods
k top node
k api-resources --namespaced=true
k api-resources --namespaced=false

k get roles --all-namespaces
k get serviceaccounts --all-namespaces
k get rolebindings --all-namespaces
k get ingresses  --all-namespaces
```
