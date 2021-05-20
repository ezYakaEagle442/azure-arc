## Plan IP addressing for your clusters

See  :

- [https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni#plan-ip-addressing-for-your-cluster](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni#plan-ip-addressing-for-your-cluster)
- [Public IP sku comparison](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-ip-addresses-overview-arm#sku)
- [https://docs.openshift.com/aro/4/networking/understanding-networking.html](https://docs.openshift.com/aro/4/networking/understanding-networking.html)
- [https://docs.microsoft.com/fr-fr/cli/azure/aro?view=azure-cli-latest](https://docs.microsoft.com/fr-fr/cli/azure/aro?view=azure-cli-latest)

```sh
# https://www.ipaddressguide.com/cidr


``` 

## AKS VNet

```sh
az network vnet create --name $aks_vnet_name --resource-group $aks_rg_name --address-prefixes 172.16.0.0/16 --location $location
az network vnet subnet create --name $aks_subnet_name --address-prefixes 172.16.1.0/24 --vnet-name $aks_vnet_name --resource-group $aks_rg_name 

aks_vnet_id=$(az network vnet show --resource-group $aks_rg_name --name $aks_vnet_name --query id -o tsv)
echo "AKS VNet Id :" $aks_vnet_id	

aks_subnet_id=$(az network vnet subnet show --resource-group $aks_rg_name --vnet-name $aks_vnet_name --name $aks_subnet_name --query id -o tsv)
echo "AKS Subnet Id :" $aks_subnet_id	

az role assignment list --assignee $aks_sp_id 
az role assignment create --assignee $aks_sp_id --scope $aks_vnet_id --role Contributor
# az role assignment create --assignee $aks_sp_id --scope $aks_subnet_id --role "Network contributor"
```

## K3S VNet
```sh
az network vnet create --name $k3s_vnet_name --resource-group $k3s_rg_name --address-prefixes 172.3.0.0/16 --location $location
az network vnet subnet create --name $k3s_subnet_name --address-prefixes 172.3.1.0/24 --vnet-name $k3s_vnet_name --resource-group $k3s_rg_name 
az network vnet subnet create --name ManagementSubnet --address-prefixes 172.3.3.0/24 --vnet-name $k3s_vnet_name --resource-group $k3s_rg_name 


k3s_vnet_id=$(az network vnet show --resource-group $k3s_rg_name --name $k3s_vnet_name --query id -o tsv)
echo "K3S VNet Id :" $k3s_vnet_id	

k3s_subnet_id=$(az network vnet subnet show --resource-group $k3s_rg_name --vnet-name $k3s_vnet_name --name $k3s_subnet_name --query id -o tsv)
echo "K3S Subnet Id :" $k3s_subnet_id
```


## ARO VNet
```sh
# ARO nodes VNet & Subnet
az network vnet create --name $aro_vnet_name --resource-group $aro_rg_name --address-prefixes 172.32.0.0/21 --location $location
az network vnet subnet create --name $aro_master_subnet_name --address-prefixes 172.32.1.0/24 --vnet-name $aro_vnet_name --resource-group $aro_rg_name --service-endpoints Microsoft.ContainerRegistry
az network vnet subnet create --name $aro_worker_subnet_name --address-prefixes 172.32.2.0/24 --vnet-name $aro_vnet_name -g $aro_rg_name --service-endpoints Microsoft.ContainerRegistry

aro_vnet_id=$(az network vnet show --resource-group $aro_rg_name --name $aro_vnet_name --query id -o tsv)
echo "VNet Id :" $aro_vnet_id	

aro_master_subnet_id=$(az network vnet subnet show --name $aro_master_subnet_name --vnet-name $aro_vnet_name  -g $aro_rg_name --query id -o tsv)
echo "Master Subnet Id :" $aro_master_subnet_id	

aro_worker_subnet_id=$(az network vnet subnet show --name $aro_worker_subnet_name --vnet-name $aro_vnet_name -g $aro_rg_name --query id -o tsv)
echo "Worker Subnet Id :" $aro_worker_subnet_id
```
