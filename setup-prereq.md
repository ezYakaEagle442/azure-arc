
#  Enable resource providers
```sh
az feature register --namespace Microsoft.Kubernetes --name previewAccess
az feature register --namespace Microsoft.KubernetesConfiguration --name sourceControlConfiguration

az feature list -o table | grep Kubernetes

az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider show -n Microsoft.Kubernetes --query  "resourceTypes[?resourceType == 'connectedClusters']".locations 
az provider show -n Microsoft.KubernetesConfiguration -o table
```


# Install Azure-Arc CLI extension

```sh
az extension list-available
az extension add -n connectedk8s --yes
az extension add -n k8sconfiguration --yes
az extension list -o table

az extension update --name connectedk8s
az extension update --name k8sconfiguration

```


# Create RG
```sh
az group create --name $aks_rg_name --location $location
az group create --name $aro_rg_name --location $location
az group create --name $k3s_rg_name --location $location
az group create --name $common_rg_name --location $location

az group create --name rg-cloudshell-$location --location $location

```

# Create Storage

This is not mandatory, you can create a storage account to play with CloudShell

```sh
# https://docs.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create
# https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction#types-of-storage-accounts
az storage account create --name stcloudshellwe --kind StorageV2 --sku Standard_LRS -g rg-cloudshell-$location --location $location --https-only true

```

# Generates your SSH keys

<span style="color:red">/!\ IMPORTANT </span> :  check & save your ssh_passphrase !!!
```sh
ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/$ssh_key -C "youremail@groland.grd"
```

# Create Service Principal


See:
-  [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/create-onboarding-service-principal](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/create-onboarding-service-principal)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsofthybridcompute](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsofthybridcompute)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)

<span style="text-decoration: underline">Note for AKS</span>: 
Read [https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal)
[Additional considerations](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal#additional-considerations)
On the agent node VMs in the Kubernetes cluster, the service principal credentials are stored in the file /etc/kubernetes/azure.json
When you use the az aks create command to generate the service principal automatically, the service principal credentials are written to the file /aksServicePrincipal.json on the machine used to run the command.
(You do not need to create SPN when enabling managed-identity on AKS cluster.)


```sh
sp_password=$(az ad sp create-for-rbac --name $appName --role contributor --query password --output tsv)
echo $sp_password > spp.txt
echo "Service Principal Password saved to ./spp.txt. IMPORTANT Keep your password ..." 
# sp_password=`cat spp.txt`
#sp_id=$(az ad sp show --id http://$appName --query objectId -o tsv)
#sp_id=$(az ad sp list --all --query "[?appDisplayName=='${appName}'].{appId:appId}" --output tsv)
sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}'].{appId:appId}" --output tsv)
echo "Service Principal ID:" $sp_id 
echo $sp_id > spid.txt
# sp_id=`cat spid.txt`
az ad sp show --id $sp_id

az role assignment create \
    --role 34e09817-6cbe-4d01-b1a2-e0eac5743d41 \
    --assignee $sp_id \
    --scope /subscriptions/$subId

```

# Get a Red Hat pull secret

See [Azure docs](https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster#get-a-red-hat-pull-secret-optional)
to connect to [Red Hat OpenShift cluster manager portal](https://cloud.redhat.com/openshift/install/azure/aro-provisioned)

Click Download pull secret from [https://cloud.redhat.com/openshift/install/azure/aro-provisioned/pull-secret](https://cloud.redhat.com/openshift/install/azure/aro-provisioned/pull-secret)
Keep the saved pull-secret.txt file somewhere safe - it will be used in each cluster creation.
When running the az aro create command, you can reference your pull secret using the --pull-secret @pull-secret.txt parameter. Execute az aro create from the directory where you stored your pull-secret.txt file. Otherwise, replace @pull-secret.txt with @<path-to-my-pull-secret-file>.

See also [https://github.com/stuartatmicrosoft/azure-aro#aro4-replace-pull-secretsh](https://github.com/stuartatmicrosoft/azure-aro#aro4-replace-pull-secretsh)
