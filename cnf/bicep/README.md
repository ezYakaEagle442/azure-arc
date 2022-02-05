# AKS

TODO : Use [Pipelines with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions?tabs=CLI)
```sh
az group create --name rg-iac-kv --location northeurope
az group create --name rg-iac-aks --location northeurope

ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/bicep_key -C "youremail@groland.grd"
cat ~/.ssh/bicep_key.pub

az deployment group create --name iac-101-kv -f ./kv/kv.bicep -g rg-iac-kv \
    --parameters @./cnf/bicep/kv/parameters.json

az deployment group create --name iac-101-aks -f ./aks/main.bicep -g rg-iac-aks \
    --parameters @./aks/parameters.json

```

# ARO

```sh
aro_sp_password=$(az ad sp create-for-rbac --name $appName-aro --role contributor --query password -o tsv)
echo $aro_sp_password > aro_spp.txt
echo "Service Principal Password saved to ./aro_spp.txt IMPORTANT Keep your password ..." 
# aro_sp_password=`cat aro_spp.txt`
#aro_sp_id=$(az ad sp show --id http://$appName-aro --query appId -o tsv) # | jq -r .appId
#aro_sp_id=$(az ad sp list --all --query "[?appDisplayName=='${appName}-aro'].{appId:appId}" --output tsv)
aro_sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}-aro'].{appId:appId}" -o tsv)
echo "Service Principal ID:" $aro_sp_id 
echo $aro_sp_id > aro_spid.txt
# aro_sp_id=`cat aro_spid.txt`
az ad sp show --id $aro_sp_id

clientObjectId="$(az ad sp list --filter "AppId eq '$aro_sp_id'" --query "[?appId=='$aro_sp_id'].objectId" -o tsv)"

aroRpObjectId="$(az ad sp list --filter "displayname eq 'Azure Red Hat OpenShift RP'" --query "[?appDisplayName=='Azure Red Hat OpenShift RP'].objectId" -o tsv)"

pull_secret=`cat pull-secret.txt`

az deployment group create --name iac-101-aro \
    -f ./aro/main.bicep \
    -g $aro_rg_name \
    --parameters clientId=$aro_sp_id \
        clientObjectId=$clientObjectId \
        clientSecret=$aro_sp_password \
        aroRpObjectId=$aroRpObjectId \
        pullSecret=$pull_secret \
        domain=openshiftrocks
```
