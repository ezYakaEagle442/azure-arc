
# Stop

```sh

# k3s
az vm show --name "$k3s_vm_name" -g $k3s_rg_name 
az vm stop --name "$k3s_vm_name" -g $k3s_rg_name
az vm deallocate --name "$k3s_vm_name" -g $k3s_rg_name

# AKS
# https://github.com/MicrosoftDocs/azure-docs/issues/70221
az aks stop --name $aks_cluster_name -g $aks_rg_name


# Demo VM
az vm show --name "vm-azarc-linux-Demo" -g RG-AZARC-SERVERS-WESTEUROPE
az vm stop --name "vm-azarc-linux-Demo" -g RG-AZARC-SERVERS-WESTEUROPE
az vm deallocate --name "vm-azarc-linux-Demo" -g rg-azarc-servers-francecentral

# Arc-Data-Client
az vm stop --name Arc-Data-Client -g rg-azarc-data-aks-pgsql-westeurope
az vm deallocate

# ARO
# https://github.com/Azure/OpenShift/issues/207



```


# Start

```sh

# k3s
az vm start --name "$k3s_vm_name" -g $k3s_rg_name

# AKS
az aks start --name $aks_cluster_name -g $aks_rg_name


# Demo VM
az vm start --name "vm-azarc-linux-Demo" -g RG-AZARC-SERVERS-WESTEUROPE

# Arc-Data-Client
az vm start --name Arc-Data-Client -g rg-azarc-data-aks-pgsql-westeurope

# Patch
az aks upgrade -n $aks_cluster_name -g $aks_rg_name --node-image-only -y

# ARO



```