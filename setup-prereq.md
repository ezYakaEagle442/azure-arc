#  Enable resource providers
```sh
az feature register --namespace Microsoft.Kubernetes --name previewAccess
az feature register --namespace Microsoft.KubernetesConfiguration --name sourceControlConfiguration

az feature list -o table | grep Kubernetes

az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider show -n Microsoft.Kubernetes --query  "resourceTypes[?resourceType == 'connectedClusters']".locations 
az provider show -n Microsoft.KubernetesConfiguration -o table

# Provider register: Register the Azure Policy provider: https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes?toc=/azure/azure-arc/kubernetes/toc.json
az provider register --namespace 'Microsoft.PolicyInsights'
```

# Install Azure-Arc CLI extension

```sh
az extension list-available
az extension add -n connectedk8s --yes
az extension add -n k8s-configuration --yes
az extension add --name connectedmachine --yes
az extension add --name customlocation --yes 
az extension list -o table

az extension update --name connectedk8s
az extension update --name connectedmachine
az extension update --name k8s-configuration
az extension update --name customlocation
```

# Create RG
```sh
az group create --name $aks_rg_name --location $location
az group create --name $aro_rg_name --location $location
az group create --name $k3s_rg_name --location $location
az group create --name $common_rg_name --location $location
az group create --name $gke_rg_name --location $location
az group create --name $eks_rg_name --location $location

az group create --name rg-cloudshell-$location --location $location
```

# Create Storage

This is not mandatory, you can create a storage account to play with CloudShell

```sh
# https://docs.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create
# https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction#types-of-storage-accounts
az storage account create --name stcloudshellfr --kind StorageV2 --sku Standard_LRS -g rg-cloudshell-$location --location $location --https-only true
```

# Generates your SSH keys

<span style="color:red">/!\ IMPORTANT </span> :  check & save your ssh_passphrase !!!
```sh
ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/$ssh_key -C "youremail@groland.grd"
```

# Get a Red Hat pull secret

See [Azure docs](https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster#get-a-red-hat-pull-secret-optional)
to connect to [Red Hat OpenShift cluster manager portal](https://cloud.redhat.com/openshift/install/azure/aro-provisioned)

Click Download pull secret from [https://cloud.redhat.com/openshift/install/azure/aro-provisioned/pull-secret](https://cloud.redhat.com/openshift/install/azure/aro-provisioned/pull-secret)
Keep the saved pull-secret.txt file somewhere safe - it will be used in each cluster creation.
When running the az aro create command, you can reference your pull secret using the --pull-secret @pull-secret.txt parameter. Execute az aro create from the directory where you stored your pull-secret.txt file. Otherwise, replace @pull-secret.txt with @<path-to-my-pull-secret-file>.

See also [https://github.com/stuartatmicrosoft/azure-aro#aro4-replace-pull-secretsh](https://github.com/stuartatmicrosoft/azure-aro#aro4-replace-pull-secretsh)

# Setup Network

[See section](setup-network.md)