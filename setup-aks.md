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

az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ExtendedLocation

az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table
az provider show -n Microsoft.ExtendedLocation -o table

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
acr_registry_id=$(az acr show --name $acr_registry_name --resource-group $aks_rg_name --query "id" --output tsv)
echo "ACR registry ID :" $acr_registry_id

```

## Create AKS Service Principal


See:
-  [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/create-onboarding-service-principal](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/create-onboarding-service-principal)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsofthybridcompute](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsofthybridcompute)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#policy-insights-data-writer-preview](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#policy-insights-data-writer-preview)
<span style="text-decoration: underline">Note for AKS</span>: 
Read [https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal)
[Additional considerations](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal#additional-considerations)
On the agent node VMs in the Kubernetes cluster, the service principal credentials are stored in the file /etc/kubernetes/azure.json
When you use the az aks create command to generate the service principal automatically, the service principal credentials are written to the file /aksServicePrincipal.json on the machine used to run the command.
(You do not need to create SPN when enabling managed-identity on AKS cluster.)


```sh
aks_sp_password=$(az ad sp create-for-rbac --name $appName-aks --role contributor --query password -o tsv)
echo $aks_sp_password > aks_spp.txt
echo "Service Principal Password saved to ./aks_spp.txt IMPORTANT Keep your password ..." 
# aks_sp_password=`cat aks_spp.txt`
aks_sp_id=$(az ad sp show --id http://$appName-aks --query appId -o tsv)
#aks_sp_id=$(az ad sp list --all --query "[?appDisplayName=='${appName}-aks'].{appId:appId}" --output tsv)
#aks_sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}-aks'].{appId:appId}" -o tsv)
echo "Service Principal ID:" $aks_sp_id 
echo $aks_sp_id > aks_spid.txt
# aks_sp_id=`cat aks_spid.txt`
az ad sp show --id $aks_sp_id

# az role assignment create \
#     --role 34e09817-6cbe-4d01-b1a2-e0eac5743d41 \
#     --assignee $aks_sp_id \
#    --scope /subscriptions/$subId

```
## Create AKS Cluster

To learn more about UDR, see [https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)


```sh

az aks create --name $aks_cluster_name \
    --resource-group $aks_rg_name \
    --node-resource-group $cluster_rg_name \
    --zones 1 2 3 \
    --enable-cluster-autoscaler \
    --min-count=1 \
    --max-count=3 \
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
    --outbound-type loadBalancer \
    --service-principal $aks_sp_id \
    --client-secret $aks_sp_password \
    --attach-acr $acr_registry_name \
    --ssh-key-value ~/.ssh/${ssh_key}.pub \
    --verbose

aks_client_id=$(az aks show --resource-group $aks_rg_name --name $aks_cluster_name --query "servicePrincipalProfile.clientId" --output tsv)
echo "AKS CLIENT_ID:" $aks_client_id 

# with SP when Managed Identities is not set during AKS cluster creation
# when Managed Identities is set during AKS cluster creation :

# aks_client_id=$(az aks show -g $rg_name -n $cluster_name --query identityProfile.kubeletidentity.clientId -o tsv)
# echo "AKS Cluster Identity Client ID " $aks_client_id

# az role assignment create --assignee $aks_client_id --role acrpull --scope $acr_registry_id

```


### Get AKS Credentials

Apply [k alias](./tools#kube-tools)

```sh

ls -al ~/.kube
# rm  ~/.kube/config

az aks get-credentials --resource-group $aks_rg_name --name $aks_cluster_name
az aks show -n $aks_cluster_name -g $aks_rg_name

cat ~/.kube/config
k cluster-info
export KUBECONFIG=~/.kube/config
k config view --minify
k config get-contexts

export KUBECONTEXT=$aks_cluster_name
k config use-context $aks_cluster_name

aks_api_server_url=$(az aks show -n $aks_cluster_name -g $aks_rg_name --query 'fqdn' -o tsv)
echo "AKS API server URL: " $aks_api_server_url

# TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

```


## Connect to the Cluster

- install the [tools](tools.md)
- reinit your variables

```sh

az aks list -o table

aks_cluster_id=$(az aks show -n $aks_cluster_name -g $aks_rg_name --query id -o tsv)
echo "AKS cluster ID : " $aks_cluster_id

```

## Optionnal Play: Create Namespaces
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

# Optional Play with nodes:

for node in $(k get nodes -o=custom-columns=':.metadata.name') # k get nodes -o jsonpath={.items[*].metadata.name}
do 
  k describe node $node
done

k get pods
k top node
k api-resources --namespaced=true
k api-resources --namespaced=false

k get roles --all-namespaces
k get serviceaccounts --all-namespaces
k get rolebindings --all-namespaces
k get ingresses  --all-namespaces
```

### Setup NSG 
```sh

aks_nsg="aks-nsg-management"
az network nsg create --name $aks_nsg -g $aks_rg_name --location $location

az network nsg rule create --access Allow --destination-port-range 22 --source-address-prefixes Internet --name "Allow SSH from Internet" --nsg-name $aks_nsg -g $aks_rg_name --priority 100

az network nsg rule create --access Allow --destination-port-range 6443 --source-address-prefixes Internet --name "Allow 6443 from Internet" --nsg-name $aks_nsg -g $aks_rg_name --priority 110

az network nsg rule create --access Allow --destination-port-range 80 --source-address-prefixes Internet --name "Allow 80 from Internet" --nsg-name $aks_nsg -g $aks_rg_name --priority 120

az network nsg rule create --access Allow --destination-port-range 8080 --source-address-prefixes Internet --name "Allow 8080 from Internet" --nsg-name $aks_nsg -g $aks_rg_name --priority 130

az network nsg rule create --access Allow --destination-port-range 32380 --source-address-prefixes Internet --name "Allow 32380 from Internet" --nsg-name $aks_nsg -g $aks_rg_name --priority 140

az network nsg rule create --access Allow --destination-port-range 32333 --source-address-prefixes Internet --name "Allow 32333 from Internet" --nsg-name $aks_nsg -g $aks_rg_name --priority 150

az network vnet subnet update --name $aks_subnet_name --network-security-group $aks_nsg --vnet-name $aks_vnet_name -g $aks_rg_name

## Deploy a dummy App.

The deployment LoadBalancer was changed to use port **32380** along side with the matching Azure Network Security Group (NSG).

```sh
k apply -f app/hello hello-kubernetes.yaml
hello_svc_cluster_ip=$(k get svc hello-kubernetes -o=custom-columns=":spec.clusterIP")
hello_svc_slb_pub_ip=$(k get svc hello-kubernetes -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
curl http://$hello_svc_slb_pub_ip:32380

echo "Test from your browser : http://$hello_svc_slb_pub_ip/hello-kubernetes "

k get deploy
k get po


```

## Register to Azure Arc.

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster)
```sh

azure_arc_ns="azure-arc"

# Deploy Azure Arc Agents for Kubernetes using Helm 3, into the azure-arc namespace
az connectedk8s connect --name $azure_arc_aks --infrastructure azure -l $location -g $aks_rg_name --kube-config $KUBECONFIG --kube-context $KUBECONTEXT
k get crds
k get azureclusteridentityrequests.clusterconfig.azure.com -n $azure_arc_ns
k describe azureclusteridentityrequests.clusterconfig.azure.com config-agent-identity-request -n $azure_arc_ns

k get managedClusters.arc.azure.com -n $azure_arc_ns
k describe managedClusters.arc.azure.com clustermetadata -n $azure_arc_ns

# verify
az connectedk8s list --subscription $subId -o table
az connectedk8s list -g $aks_rg_name -o table # -c $azure_arc_aks --cluster-type managedClusters 
az connectedk8s show --name $azure_arc_aks -g $aks_rg_name 
helm status azure-arc --namespace default 

# Azure Arc enabled Kubernetes deploys a few operators into the azure-arc namespace. You can view these deployments and pods here:
k get deploy,po -n $azure_arc_ns 
k get po -o=custom-columns=':metadata.name' -n $azure_arc_ns
k get po -l app.kubernetes.io/component=connect-agent -n $azure_arc_ns
k get po -l app.kubernetes.io/component=config-agent -n $azure_arc_ns
k get po -l app.kubernetes.io/component=flux-logs-agent -n $azure_arc_ns
k get po -l app.kubernetes.io/component=cluster-metadata-operator -n $azure_arc_ns
k get po -l app.kubernetes.io/component=resource-sync-agent -n $azure_arc_ns

k logs -l app.kubernetes.io/component=config-agent -c config-agent -n $azure_arc_ns 

# -o tsv is MANDATORY to remove quotes
azure_arc_aks_id=$(az connectedk8s show --name $azure_arc_aks -g $aks_rg_name -o tsv --query id)

```

## Enable GitOps on a connected cluster

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-connected-cluster](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-connected-cluster)

### Create Config for GitOps workflow

Fork this [sample repo](https://github.com/Azure/arc-k8s-demo) into your GitHub account 

The Config Agent on AKS cluster requires a Service Principal (SPN) for authentication, thus you can enable this capability only for SPN-based AKS clusters. 
AKS clusters created with Managed Identity (MSI) are not supported yet.

```sh

tenantId=$(az account show --query tenantId -o tsv)
git clone $gitops_url

k create namespace $arc_gitops_namespace

# https://docs.fluxcd.io/en/1.17.1/faq.html#will-flux-delete-resources-when-i-remove-them-from-git
# Will Flux delete resources when I remove them from git?
# Flux has an garbage collection feature, enabled by passing the command-line flag --sync-garbage-collection to fluxd
az k8s-configuration create --name $arc_config_name_aks --cluster-name $azure_arc_aks -g $aks_rg_name --cluster-type connectedClusters \
  --repository-url $gitops_url \
  --enable-helm-operator true \
  --helm-operator-chart-version='1.2.0' \
  --helm-operator-params '--set helm.versions=v3' \
  --operator-namespace $arc_gitops_namespace \
  --operator-instance-name $arc_operator_instance_name_aks \
  --operator-type flux \
  --operator-params='--git-poll-interval=1m --sync-garbage-collection' \
  --scope cluster # namespace

az k8s-configuration list --cluster-name $azure_arc_aks -g $aks_rg_name --cluster-type connectedClusters
az k8s-configuration show --name $arc_config_name_aks --cluster-name $azure_arc_aks -g $aks_rg_name --cluster-type connectedClusters

repositoryPublicKey=$(az k8s-configuration show --cluster-name $azure_arc_aks --name $arc_config_name_aks -g $aks_rg_name --cluster-type connectedClusters --query 'repositoryPublicKey')
echo "repositoryPublicKey : " $repositoryPublicKey
echo "Add this Public Key to your GitHub Project Deploy Key and allow write access at https://github.com/$github_usr/arc-k8s-demo/settings/keys"

# notices the new Pending configuration
complianceState=$(az k8s-configuration show --cluster-name $azure_arc_aks --name $arc_config_name_aks -g $aks_rg_name --cluster-type connectedClusters --query 'complianceStatus.complianceState')
echo "Compliance State " : $complianceState

k get events -A 
k get gitconfigs.clusterconfig.azure.com -n $arc_gitops_namespace
k describe gitconfigs.clusterconfig.azure.com -n $arc_gitops_namespace

# https://kubernetes.io/docs/concepts/extend-kubernetes/operator
# https://github.com/fluxcd/helm-operator/blob/master/chart/helm-operator/CHANGELOG.md#060-2020-01-26
k get po -L app=helm-operator -A
k describe po aks-cluster-config-helm-gitops-helm-operator-c546b564b-glcf5 -n $arc_gitops_namespace | grep -i "image" # ==> Image: docker.io/fluxcd/helm-operator:1.0.0-rc4
# https://hub.docker.com/r/fluxcd/helm-operator/tags
```

### Config Private repo 
If you are using a private git repo, then you need to perform one more task to close the loop: you need to add the public key that was generated by flux as a Deploy key in the repo.
```sh
az k8s-configuration show --cluster-name $azure_arc_aks --name $arc_config_name_aks -g $aks_rg_name --cluster-type managedClusters --query 'repositoryPublicKey'
```

### Validate the Kubernetes configuration
```sh
k get ns --show-labels
k -n team-a get cm -o yaml
k -n itops get all
k get ep -n gitops
k get events
flux_logs_agent_pod=$(k get po -l app.kubernetes.io/component=flux-logs-agent -n $azure_arc_ns -o jsonpath={.items[0].metadata.name})
k logs $flux_logs_agent_pod -c flux-logs-agent -n $azure_arc_ns 
# az k8s-configuration delete --name '<config name>' -g '<resource group name>' --cluster-name '<cluster name>' --cluster-type managedClusters
helm ls
```

## Deploy applications using Helm and GitOps

You can learn more about the HelmRelease in the official [Helm Operator documentation](https://docs.fluxcd.io/projects/helm-operator/en/stable/references/helmrelease-custom-resource)

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-with-helm](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-with-helm)

```sh

az k8s-configuration create --name "$arc_config_name_aks-voting-app" --cluster-name $azure_arc_aks -g $aks_rg_name \
  --operator-instance-name "$arc_operator_instance_name_aks-voting-app" \
  --operator-namespace prod \
  --enable-helm-operator \
  --helm-operator-chart-version='1.2.0' \
  --helm-operator-params='--set helm.versions=v3' \
  --repository-url $gitops_helm_url \
  --operator-params='--git-readonly --git-path=releases/prod' \
  --scope namespace \
  --cluster-type connectedClusters

az k8s-configuration show --resource-group $aks_rg_name --name "$arc_config_name_aks-voting-app" --cluster-name $azure_arc_aks --cluster-type connectedClusters

# notices the new Pending configuration
complianceState=$(az k8s-configuration show --cluster-name $azure_arc_aks --name "$arc_config_name_aks-voting-app" -g $aks_rg_name --cluster-type connectedClusters --query 'complianceStatus.complianceState')
echo "Compliance State " : $complianceState

# Verify the App
k get po -n prod
k get svc/azure-vote-front -n prod
azure_vote_front_url=$(k get svc/azure-vote-front -n prod -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
# Find the external IP address from the output above and open it in a browser.
echo "Open your brower to test the App at $azure_vote_front_url"

```

## Use Azure Policy to enable GitOps on clusters at scale

See:
- [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-azure-policy](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-azure-policy)
- [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/policy-samples](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/policy-samples)
- [https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources](https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources)
- [https://docs.microsoft.com/fr-fr/cli/azure/policy/definition?view=azure-cli-latest#az-policy-definition-create](https://docs.microsoft.com/fr-fr/cli/azure/policy/definition?view=azure-cli-latest#az-policy-definition-create)
- [https://docs.microsoft.com/fr-fr/cli/azure/policy/remediation?view=azure-cli-latest#az-policy-remediation-create](https://docs.microsoft.com/fr-fr/cli/azure/policy/remediation?view=azure-cli-latest#az-policy-remediation-create)
Use Case: Use Azure Policy to enforce that each Microsoft.Kubernetes/connectedclusters resource or Git-Ops enabled Microsoft.ContainerService/managedClusters resource has specific Microsoft.KubernetesConfiguration/sourceControlConfigurations applied on it.
You can use the above doc to follow steps by steps guidance in the portal , using "Deploy GitOps to Kubernetes cluster" built-in policy in the "Kubernetes" category.
Other option you can use CLI to apply this policy running the snippet below.
```sh
Assure-GitOps-endpoint-for-Kubernetes-cluster.json

az policy definition list | grep -i "kubernetes"  
az policy definition create --name "aks-gitops-enforcement"
                            --description "Ensure to deploy GitOps to AKS Kubernetes cluster"
                            --display-name "aks-gitops-enforcement"
                            [--management-group]
                            [--metadata]
                            [--mode]
                            --params --git-poll-interval=1m
                            [--rules]
                            [--subscription]

az policy assignment list -g $aks_rg_name

gitOpsAssignmentId=$(az policy assignment show --name xxx -g $aks_rg_name --query id)

# Create a remediation for a specific assignment
az policy remediation start ...
```


## Monitor a connected cluster with Azure Monitor for containers

See :
- [https://aka.ms/arc-k8s-ci-onboarding](https://aka.ms/arc-k8s-ci-onboarding)

### Pre-req
See the [doc](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-enable-arc-enabled-clusters#prerequisites)

- To enable and access the features in Azure Monitor for containers, at a minimum you need to be a member of the Azure Contributor role in the Azure subscription, and a member of the Log Analytics Contributor role of the Log Analytics workspace configured with Azure Monitor for containers.
- You are a member of the Contributor role on the Azure Arc cluster resource.
- To view the monitoring data, you are a member of the Log Analytics reader role permission with the Log Analytics workspace configured with Azure Monitor for containers.
- [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/extensions#prerequisites](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/extensions#prerequisites)

### Setup

<span style="color:red">/!\ IMPORTANT </span> : The same analytics workspace is shared for all k8s clusters, do not recreate it if it was already created in previous use case.

```sh
az monitor log-analytics workspace create -n $analytics_workspace_name --location $location -g $aks_rg_name --verbose
az monitor log-analytics workspace list
az monitor log-analytics workspace show -n $analytics_workspace_name -g $aks_rg_name --verbose

# -o tsv to manage quotes issues
export analytics_workspace_id=$(az monitor log-analytics workspace show -n $analytics_workspace_name -g $aks_rg_name --query id -o tsv)
echo "analytics_workspace_id:" $analytics_workspace_id

# https://github.com/Azure/azure-cli/issues/9228
# az aks enable-addons --addons monitoring --name $aks_cluster_name --workspace-resource-id $analytics_workspace_id -g $aks_rg_name  # --subscription $subId

# export azureArc_AKS_ClusterResourceId=$(az connectedk8s show -g $aks_rg_name --name $azure_arc_aks --query id)
export azureArc_AKS_ClusterResourceId=$(az aks show -n $aks_cluster_name -g $aks_rg_name --query 'id' -o tsv)

k config view --minify
k config get-contexts
k config current-context
k config use-context $KUBECONTEXT

# curl -o enable-monitoring.sh -L https://aka.ms/enable-monitoring-bash-script
# bash enable-monitoring.sh --resource-id $azureArc_AKS_ClusterResourceId --workspace-id $analytics_workspace_id --kube-context $KUBECONTEXT

helm ls --kube-context $KUBECONTEXT -v=10
helm search repo azuremonitor-containers

az k8s-extension create --name azuremonitor-containers --cluster-name $aks_cluster_name --resource-group $aks_rg_name --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers --configuration-settings logAnalyticsWorkspaceResourceID=$analytics_workspace_id omsagent.resources.daemonset.limits.cpu=150m omsagent.resources.daemonset.limits.memory=600Mi omsagent.resources.deployment.limits.cpu=1 omsagent.resources.deployment.limits.memory=750Mi

az k8s-extension list --cluster-name $aks_cluster_name --resource-group $aks_rg_name --cluster-type connectedClusters 
azmon_extension_state=$(az k8s-extension show --name azuremonitor-containers --cluster-name $aks_cluster_name --resource-group $aks_rg_name --cluster-type connectedClusters --query 'installState')
echo "Azure Monitor extension state: " $azmon_extension_state

# with ARM
curl -L https://aka.ms/arc-k8s-azmon-extension-arm-template -o arc-k8s-azmon-extension-arm-template.json
curl -L https://aka.ms/arc-k8s-azmon-extension-arm-template-params -o  arc-k8s-azmon-extension-arm-template-params.json

az deployment group create --resource-group  $aks_rg_name --template-file ./arc-k8s-azmon-extension-arm-template.json --parameters @./arc-k8s-azmon-extension-arm-template-params.json


```
Verify :
- By default, the containerized agent collects the stdout/ stderr container logs of all the containers running in all the namespaces except kube-system. To configure container log collection specific to particular namespace or namespaces, review [Container Insights agent configuration](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-agent-config) to configure desired data collection settings to your ConfigMap configurations file.
- To learn how to stop monitoring your Arc enabled Kubernetes cluster with Azure Monitor for containers, see [How to stop monitoring your hybrid cluster](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-optout-hybrid#how-to-stop-monitoring-on-arc-enabled-kubernetes).


## Manage Kubernetes policy within a connected cluster with Azure Policy for Kubernetes

See [https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes?toc=/azure/azure-arc/kubernetes/toc.json](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes?toc=/azure/azure-arc/kubernetes/toc.json)

See also :
- [https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes?toc=/azure/azure-arc/kubernetes/toc.json](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes?toc=/azure/azure-arc/kubernetes/toc.json)
- [https://docs.microsoft.com/en-us/azure/governance/policy/concepts/rego-for-aks?](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/rego-for-aks?)
- [https://docs.microsoft.com/en-us/azure/security-center/security-center-permissions](https://docs.microsoft.com/en-us/azure/security-center/security-center-permissions)
- [https://docs.microsoft.com/en-us/azure/governance/policy/how-to/programmatically-create](https://docs.microsoft.com/en-us/azure/governance/policy/how-to/programmatically-create)
- [https://docs.microsoft.com/en-us/azure/security-center/security-center-permissions](https://docs.microsoft.com/en-us/azure/security-center/security-center-permissions)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#security-admin](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#security-admin)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#resource-policy-contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#resource-policy-contributor)
- [https://github.com/Azure/Community-Policy/tree/master/Policies/KubernetesService/append-aks-api-ip-restrictions](https://github.com/Azure/Community-Policy/tree/master/Policies/KubernetesService/append-aks-api-ip-restrictions)
- [https://docs.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies#kubernetes](https://docs.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies#kubernetes)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#policy-insights-data-writer-preview](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#policy-insights-data-writer-preview)
- [https://www.openpolicyagent.org](https://www.openpolicyagent.org)
- [https://github.com/open-policy-agent/gatekeeper](https://github.com/open-policy-agent/gatekeeper)

The Kubernetes cluster must be version 1.14 or higher.

![OPA](./img/opa.png)

```sh
tenantId=$(az account show --query tenantId -o tsv)

az policy definition list | grep -i "kubernetes" | grep "displayName"

# https://docs.microsoft.com/en-us/cli/azure/role/definition?view=azure-cli-latest#az-role-definition-list
az role definition list | grep -i "Policy Insights Data Writer"  

helm search repo azure-policy

# Setup directly on AKS
az aks enable-addons --addons azure-policy --name $aks_cluster_name --resource-group $aks_rg_name

# Setup on AKS as Arc enabled cluster
#helm install azure-policy-addon azure-policy/azure-policy-addon-arc-clusters \
#    --set azurepolicy.env.resourceid=$azure_arc_aks_id \
#    --set azurepolicy.env.clientid=$aks_sp_id \
#    --set azurepolicy.env.clientsecret=$aks_sp_password  \
#    --set azurepolicy.env.tenantid=$tenantId

helm ls
# azure-policy pod is installed in kube-system namespace
k get pods -n kube-system

# gatekeeper pod is installed in gatekeeper-system namespace
k get pods -n gatekeeper-system

# Get the Azure-Policy pod name installed in kube-system namespace
# -l app=azure-policy-webhook 
for pod in $(k get po -l app=azure-policy -n kube-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^azure-policy.*" ]]
    then
      echo "Verifying Azure-Policy Pod $pod"
      # k describe pod $pod -n kube-system
      k logs $pod -n kube-system # | grep -i "Error"
      # k exec $pod -n kube-system -it -- /bin/sh
  fi
done

# Get the GateKeeper pod name installed in gatekeeper-system namespace
for pod in $(k get po -l gatekeeper.sh/system=yes -n gatekeeper-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^gatekeeper.*" ]]
    then
      echo "Verifying GateKeeper Pod $pod"
      # k describe pod $pod -n gatekeeper-system
      k logs $pod -n gatekeeper-system  | grep -i "Error"
      # k exec $pod -n gatekeeper-system -it -- /bin/sh
  fi
done

```
[Assign a built-in policy definition](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes?toc=/azure/azure-arc/kubernetes/toc.json#assign-a-built-in-policy-definition)

Ex: "Preview: Do not allow [privileged containers](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) in Kubernetes cluster"
By default, Docker containers are “unprivileged” and cannot, for example, run a Docker daemon inside a Docker container. This is because by default a container is not allowed to access any devices, but a “privileged” container is given access to all devices (see the documentation on cgroups devices).

When the operator executes docker run --privileged, Docker will enable access to all devices on the host as well as set some configuration in AppArmor or SELinux to allow the container nearly all the same access to the host as processes running outside containers on the host.

See also this [blog](https://blog.trailofbits.com/2019/07/19/understanding-docker-container-escapes)

Wait for a few minutes and check the logs :

```sh

k get ns

for pod in $(k get po -l app=azure-policy -n kube-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^azure-policy.*" ]]
    then
      echo "Verifying Azure-Policy Pod $pod"
      k logs $pod -n kube-system # | grep -i "Error"
  fi
done

for pod in $(k get po -l gatekeeper.sh/system=yes -n gatekeeper-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^gatekeeper.*" ]]
    then
      echo "Verifying GateKeeper Pod $pod"
      k logs $pod -n gatekeeper-system  # | grep -i "Error"
  fi
done

k get crds
# k get configs.config.gatekeeper.sh -n gatekeeper-system
# k describe configs.config.gatekeeper.sh -n gatekeeper-system

container_no_privilege_constraint=$(k get k8sazurecontainernoprivilege.constraints.gatekeeper.sh -n gatekeeper-system -o jsonpath="{.items[0].metadata.name}")
k describe k8sazurecontainernoprivilege.constraints.gatekeeper.sh $container_no_privilege_constraint -n gatekeeper-system

# https://github.com/Azure/azure-policy/tree/master/samples/KubernetesService
# https://github.com/Azure/azure-policy/tree/master/built-in-policies/policyDefinitions/Kubernetes%20service
# https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-references/Kubernetes/container-no-privilege/template.yaml
# https://github.com/open-policy-agent/gatekeeper/tree/master/library/pod-security-policy/privileged-containers replaced by https://github.com/open-policy-agent/gatekeeper-library/tree/master/library/general

# Try to deploy a "bad" Pod
k apply -f app/root-pod.yaml

# You should see the error below
Error from server ([denied by azurepolicy-container-no-privilege-dc2585889397ecb73d135643b3e0e0f2a6da54110d59e676c2286eac3c80dab5] Privileged container is not allowed: root-demo, securityContext: {"privileged": true}): error when creating "root-demo-pod.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [denied by azurepolicy-container-no-privilege-dc2585889397ecb73d135643b3e0e0f2a6da54110d59e676c2286eac3c80dab5] Privileged container is not allowed: root-demo, securityContext: {"privileged": true}


```

## IoT Edge workloads integration

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/deploy-azure-iot-edge-workloads](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/deploy-azure-iot-edge-workloads)

```sh

```

## Troubleshooting

See [Azure Arc doc](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/troubleshooting)

# Clean-Up
```sh

export KUBECONFIG=~/.kube/config
k config use-context $aks_cluster_name
k config view --minify
k config get-contexts
export KUBECONTEXT=$aks_cluster_name


helm uninstall azure-policy-addon

az connectedk8s delete --name $azure_arc_aks -g $aks_rg_name -y # --kube-config $KUBECONFIG --kube-context $KUBECONTEXT


# az aks disable-addons -a monitoring -n $aks_cluster_name -g $aks_rg_name

# curl -o disable-monitoring.sh -L https://aka.ms/disable-monitoring-bash-script
# bash disable-monitoring.sh --resource-id $azureArc_AKS_ClusterResourceId --kube-context $KUBECONTEXT
# az monitor log-analytics workspace delete --workspace-name $analytics_workspace_name -g $aks_rg_name

az k8s-extension delete --name azuremonitor-containers --cluster-type connectedClusters --cluster-name $aks_cluster_name  -g $aks_rg_name

# helm uninstall azuremonitor-containers
# helm uninstall azmon-containers-release-1

k delete ds omsagent -n kube-system
k delete ds omsagent-win -n kube-system

k delete serviceaccounts omsagent -n kube-system #

for deployment in $(k get deployments -l component=oms-agent -n kube-system -o=custom-columns=:.metadata.name)
do
  if [[ "$deployment"="^oms.*" ]]
    then
      echo "Deleting OMS Deployment $deployment"
      k delete deployment $deployment -n kube-system
  fi
done

for pod in $(k get po -l component=oms-agent -n kube-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^oms.*" ]]
    then
      echo "Deleting OMS Pod $pod"
      k delete pod $pod -n kube-system
      # k describe pod $pod -n kube-system
      # k logs $pod -n kube-system  | grep -i "Error"
  fi
done
k get po -l component=oms-agent -n kube-system


az k8s-configuration delete --name "$arc_config_name_aks-azure-voting-app" --cluster-name $azure_arc_aks --cluster-type managedClusters -g $aks_rg_name -y
az k8s-configuration delete --name $arc_config_name_aks --cluster-name $azure_arc_aks --cluster-type managedClusters -g $aks_rg_name -y

# az policy definition delete --name "aks-gitops-enforcement"
az policy assignment delete --name xxx -g $aks_rg_name

az connectedk8s delete --name $azure_arc_aks -g $aks_rg_name -y

az aks delete --name $aks_cluster_name -g $aks_rg_name -y

# ACR
az acr delete -g $aks_rg_name --name $acr_registry_name -y

