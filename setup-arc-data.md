See :
- [https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_postgresql_hyperscale_arm_template](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_postgresql_hyperscale_arm_template/)
- [https://docs.microsoft.com/en-us/azure/azure-arc/data/overview](https://docs.microsoft.com/en-us/azure/azure-arc/data/overview)

# Pre-req
```sh
arc_data_sp_password=$(az ad sp create-for-rbac --name $appName-data --role contributor --query password -o tsv)
echo $arc_data_sp_password > arc_data_sp_password.txt
echo "Service Principal Password saved to ./arc_data_sp_password.txt IMPORTANT Keep your password ..." 
# arc_data_sp_password=`cat arc_data_sp_password.txt`
arc_data_sp_id=$(az ad sp show --id http://$appName-data --query appId -o tsv)
#arc_data_sp_id=$(az ad sp list --all --query "[?appDisplayName=='${appName}-data'].{appId:appId}" --output tsv)
#arc_data_sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}-data'].{appId:appId}" -o tsv)
echo "Arc for data Service Principal ID:" $arc_data_sp_id 
echo $arc_data_sp_id > arc_data_sp_id.txt
# arc_data_sp_id=`cat arc_data_sp_id.txt`
az ad sp show --id $arc_data_sp_id
```

```sh
az provider register --namespace Microsoft.AzureArcData
az provider show -n Microsoft.AzureArcData -o table
```

# AKS Setup

**Note: Currently, On Azure Kubernetes Service (AKS), Kubernetes version 1.19.x is not supported.**

```sh
cd /azure_arc/azure_arc_data_jumpstart/aks/arm_template/postgres_hs
az aks get-versions -l $location

arc_data_aks_rg_name="rg-${appName}-data-aks-pgsql-${location}" 

az group create --name $arc_data_aks_rg_name --location $location

az deployment group create \
--resource-group $arc_data_aks_rg_name \
--name ${appName}-data-aks-pgsql \
--template-uri https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_data_jumpstart/aks/arm_template/postgres_hs/azuredeploy.json \
--parameters /aks/arm_template/postgres_hs/azuredeploy.parameters.json


```