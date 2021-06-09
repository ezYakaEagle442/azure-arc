See:
- [Azure ARO docs](https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster)
- [ARO 4.x docs](https://docs.openshift.com/aro/4/registry/architecture-component-imageregistry.html)
- [http://aroworkshop.io](http://aroworkshop.io)
- [https://aka.ms/aroworkshop-devops](https://aka.ms/aroworkshop-devops)


# pre-requisites
```sh
# Provider register: Register the Azure Policy provider
az provider register --namespace Microsoft.PolicyInsights

az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ExtendedLocation

az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table
az provider show -n Microsoft.ExtendedLocation -o table
```

# Setup ARO

Pre-req: ensure you have installed the [ARO CLI extension](./tools#install-the-az-aro-extension)


## Create ARO Service Principal


See:
-  [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/create-onboarding-service-principal](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/create-onboarding-service-principal)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsofthybridcompute](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsofthybridcompute)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#policy-insights-data-writer-preview](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#policy-insights-data-writer-preview)

```sh
aro_sp_password=$(az ad sp create-for-rbac --name $appName-aro --role contributor --query password -o tsv)
echo $aro_sp_password > aro_spp.txt
echo "Service Principal Password saved to ./aro_spp.txt IMPORTANT Keep your password ..." 
# aro_sp_password=`cat aro_spp.txt`
aro_sp_id=$(az ad sp show --id http://$appName-aro --query appId -o tsv)
#aro_sp_id=$(az ad sp list --all --query "[?appDisplayName=='${appName}-aro'].{appId:appId}" --output tsv)
#aro_sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}-aro'].{appId:appId}" -o tsv)
echo "Service Principal ID:" $aro_sp_id 
echo $aro_sp_id > aro_spid.txt
# aro_sp_id=`cat aro_spid.txt`
az ad sp show --id $aro_sp_id

# az role assignment create \
#     --role 34e09817-6cbe-4d01-b1a2-e0eac5743d41 \
#     --assignee $aro_sp_id \
#    --scope /subscriptions/$subId

```

```sh

pull_secret=`cat pull-secret.txt`

az provider show -n  Microsoft.RedHatOpenShift --query  "resourceTypes[?resourceType == 'OpenShiftClusters']".locations 
curl -sSL aka.ms/where/aro | bash

az aro create \
  --name $aro_cluster_name \
  --vnet $aro_vnet_name \
  --master-subnet $aro_master_subnet_id	\
  --worker-subnet $aro_worker_subnet_id \
  --apiserver-visibility $aro_apiserver_visibility \
  --ingress-visibility  $aro_ingress_visibility \
  --location $location \
  --pod-cidr $aro_pod_cidr \
  --service-cidr $aro_svc_cidr \
  --pull-secret @pull-secret.txt \
  --worker-count 3 \
  --resource-group $aro_rg_name \
  --client-id $aro_sp_id \
  --client-secret $aro_sp_password

az aro list -g $aro_rg_name
az aro show -n $aro_cluster_name -g $aro_rg_name

aro_api_server_url=$(az aro show -n $aro_cluster_name -g $aro_rg_name --query 'apiserverProfile.url' -o tsv)
echo "ARO API server URL: " $aro_api_server_url

aro_version=$(az aro show -n $aro_cluster_name -g $aro_rg_name --query 'clusterProfile.version' -o tsv)
echo "ARO version : " $aro_version

aro_console_url=$(az aro show -n $aro_cluster_name -g $aro_rg_name --query 'consoleProfile.url' -o tsv)
echo "ARO console URL: " $aro_console_url

aro_ing_ctl_ip=$(az aro show -n $aro_cluster_name -g $aro_rg_name --query 'ingressProfiles[0].ip' -o tsv)
echo "ARO Ingress Controller IP: " $aro_ing_ctl_ip

aro_spn=$(az aro show -n $aro_cluster_name -g $aro_rg_name --query 'servicePrincipalProfile.clientId' -o tsv)
echo "ARO Service Principal Name: " $aro_spn

aro_managed_rg=$(az aro show -n $aro_cluster_name -g $aro_rg_name --query 'clusterProfile.resourceGroupId' -o tsv)
echo "ARO Managed Resource Group : " $aro_managed_rg

aro_cluster_id=$(az aro show -n $aro_cluster_name -g $aro_rg_name --query 'id' -o tsv)
echo "ARO Cluster Resource ID : " $aro_cluster_id

aro_managed_rg_name=`echo -e $aro_managed_rg | cut -d  "/" -f5`
echo "ARO RG Name" $aro_managed_rg_name

```
## Connect to the Cluster

See [https://docs.microsoft.com/en-us/azure/openshift/tutorial-connect-cluster#connect-to-the-cluster](https://docs.microsoft.com/en-us/azure/openshift/tutorial-connect-cluster#connect-to-the-cluster)

```sh
az aro list-credentials -n $aro_cluster_name -g $aro_rg_name
aro_usr=$(az aro list-credentials -n $aro_cluster_name -g $aro_rg_name | jq -r '.kubeadminUsername')
aro_pwd=$(az aro list-credentials -n $aro_cluster_name -g $aro_rg_name | jq -r '.kubeadminPassword')

# Launch the console URL in a browser and login using the kubeadmin credentials.

```

## Install the OpenShift CLI

See [https://docs.microsoft.com/en-us/azure/openshift/tutorial-connect-cluster#install-the-openshift-cli](https://docs.microsoft.com/en-us/azure/openshift/tutorial-connect-cluster#install-the-openshift-cli)
```sh
cd ~

aro_download_url=${aro_console_url/console/downloads}
echo "aro_download_url" $aro_download_url

wget $aro_download_url/amd64/linux/oc.tar

mkdir openshift
tar -xvf oc.tar -C openshift
echo 'export PATH=$PATH:~/openshift' >> ~/.bashrc && source ~/.bashrc
oc version

source <(oc completion bash)
echo "source <(oc completion bash)" >> ~/.bashrc 

oc login $aro_api_server_url -u $aro_usr -p $aro_pwd
oc whoami
oc cluster-info
oc config current-context
oc describe ingresscontroller default -n openshift-ingress-operator

```

Apply [KubeCtl alias](./tools#kube-tools)

## Create Namespaces
```sh

oc config view --minify | grep namespace

oc create namespace development
oc label namespace/development purpose=development

oc create namespace staging
oc label namespace/staging purpose=staging

oc create namespace production
oc label namespace/production purpose=production

oc create namespace sre
oc label namespace/sre purpose=sre

oc get ns --show-labels
oc describe namespace production
oc describe namespace sre
```

## Optionnal Play: what resources are in your cluster

```sh
oc get nodes

# https://docs.microsoft.com/en-us/azure/aro/availability-zones#verify-node-distribution-across-zones
oc describe nodes | grep -e "Name:" -e "failure-domain.beta.kubernetes.io/zone"

oc get pods
oc top node
oc api-resources --namespaced=true
oc api-resources --namespaced=false
oc get crds

oc get serviceaccounts --all-namespaces
oc get roles --all-namespaces
oc get rolebindings --all-namespaces
oc get ingresses  --all-namespaces

```

### ARO Config

[Pre-req](https://docs.microsoft.com/en-in/azure/azure-arc/kubernetes/quickstart-connect-cluster#prerequisites): If you want to connect a OpenShift cluster to Azure Arc, you need to execute the following command just once on your cluster before running az connectedk8s connect:

```sh
oc adm policy add-scc-to-user privileged system:serviceaccount:azure-arc:azure-arc-kube-aad-proxy-sa
```


## Register to Azure Arc.

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster)
```sh

azure_arc_ns="azure-arc"

export KUBECONFIG=~/.kube/config

 # find out your ARO Context , like "default/api-yt5187tl-westeurope-aroapp-io:6443/kube:admin"
# cat $KUBECONFIG | grep -i "name" | grep -i "api" | cut -d : -f2
aro_ctx=$(sudo cat $KUBECONFIG | grep -i "name: default")
ctx_length=$(echo -e $aro_ctx | wc -c)
export kubeContext="${aro_ctx:8:$ctx_length}"

oc config use-context $kubeContext
oc config get-contexts
oc config view --minify
oc config current-context

# Deploy Azure Arc Agents for Kubernetes using Helm 3, into the azure-arc namespace
az connectedk8s connect --name $azure_arc_aro --infrastructure azure -l $location -g $aro_rg_name
oc get crds
oc get azureclusteridentityrequests.clusterconfig.azure.com -n $azure_arc_ns
oc describe azureclusteridentityrequests.clusterconfig.azure.com config-agent-identity-request -n $azure_arc_ns

oc get connectedclusters.arc.azure.com -n $azure_arc_ns
oc describe connectedclusters.arc.azure.com clustermetadata -n $azure_arc_ns

# verify
az connectedk8s list --subscription $subId -o table
az connectedk8s list -g $aro_rg_name -o table # -c $azure_arc_aro --cluster-type connectedClusters 

az connectedk8s show --name $azure_arc_aro -g $aro_rg_name -o tsv --query connectivityStatus

# -o tsv is MANDATORY to remove quotes
azure_arc_aro_id=$(az connectedk8s show --name $azure_arc_aro -g $aro_rg_name -o tsv --query id)

helm status azure-arc --namespace default 

# Azure Arc enabled Kubernetes deploys a few operators into the azure-arc namespace. You can view these deployments and pods here:
oc get deploy,po -n $azure_arc_ns 
oc get po -o=custom-columns=':metadata.name' -n $azure_arc_ns
oc get po -l app.kubernetes.io/component=connect-agent -n $azure_arc_ns
oc get po -l app.kubernetes.io/component=config-agent -n $azure_arc_ns
oc get po -l app.kubernetes.io/component=flux-logs-agent -n $azure_arc_ns
oc get po -l app.kubernetes.io/component=cluster-metadata-operator -n $azure_arc_ns
oc get po -l app.kubernetes.io/component=resource-sync-agent -n $azure_arc_ns

oc logs -l app.kubernetes.io/component=config-agent -c config-agent -n $azure_arc_ns 

```


## Enable GitOps on a connected cluster

See [https://aka.ms/AzureArcK8sUsingGitOps](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-connected-cluster)

### Create Config for GitOps workflow

Foroc this [sample repo](https://github.com/Azure/arc-k8s-demo) into your GitHub account 

```sh

git clone $gitops_url

oc create namespace $arc_gitops_namespace

# https://docs.fluxcd.io/en/1.17.1/faq.html#will-flux-delete-resources-when-i-remove-them-from-git
# Will Flux delete resources when I remove them from git?
# Flux has an garbage collection feature, enabled by passing the command-line flag --sync-garbage-collection to fluxd
az k8s-configuration create --name $arc_config_name_aro --cluster-name $azure_arc_aro -g $aro_rg_name --cluster-type connectedClusters \
  --repository-url $gitops_url \
  --enable-helm-operator true \
  --helm-operator-params '--set helm.versions=v3' \
  --operator-namespace $arc_gitops_namespace \
  --operator-instance-name $arc_operator_instance_name_aro \
  --operator-type flux \
  --operator-params='--git-poll-interval=1m --sync-garbage-collection' \
  --scope cluster # namespace

az k8s-configuration list --cluster-name $azure_arc_aro -g $aro_rg_name --cluster-type connectedClusters
az k8s-configuration show --cluster-name $azure_arc_aro --name $arc_config_name_aro -g $aro_rg_name --cluster-type connectedClusters

repositoryPublicKey=$(az k8s-configuration show --cluster-name $azure_arc_aro --name $arc_config_name_aro -g $aro_rg_name --cluster-type connectedClusters --query 'repositoryPublicKey')
echo "repositoryPublicKey : " $repositoryPublicKey
echo "Add this Public Key to your GitHub Project Deploy Key and allow write access at https://github.com/$github_usr/arc-k8s-demo/settings/keys"

echo "If you forget to add the GitHub SSH Key, you will see in the GitOps pod the error below : "
echo "Permission denied (publickey). fatal: Could not read from remote repository.\n\nPlease make sure you have the correct access rights nand the repository exists."

# troubleshooting: 
for pod in $(k get po -L app=helm-operator -n $arc_gitops_namespace -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"=~"^$arc_operator_instance_name_aro*" ]]
    then
      echo "Verifying GitOps config Pod $pod"
      k logs $pod -n $arc_gitops_namespace | grep -i "Error"
      k logs $pod -n $arc_gitops_namespace | grep -i "Permission denied (publickey)"
  fi
done


# notices the new Pending configuration
complianceState=$(az k8s-configuration show --cluster-name $azure_arc_aro --name $arc_config_name_aro -g $aro_rg_name --cluster-type connectedClusters --query 'complianceStatus.complianceState')
echo "Compliance State " : $complianceState

git_config=$(oc get gitconfigs.clusterconfig.azure.com -n $arc_gitops_namespace -o jsonpath={.items[0].metadata.name})
oc describe gitconfigs.clusterconfig.azure.com $git_config -n $arc_gitops_namespace

# https://kubernetes.io/docs/concepts/extend-kubernetes/operator
# https://github.com/fluxcd/helm-operator/blob/master/chart/helm-operator/CHANGELOG.md#060-2020-01-26
oc get po -L app=helm-operator -n $arc_gitops_namespace
oc describe po aro-cluster-config-helm-gitops-helm-operator-867c66bcf4-mzcps -n $arc_gitops_namespace | grep -i "image" # ==> Image: docker.io/fluxcd/helm-operator:1.0.0-rc4
# https://hub.docker.com/r/fluxcd/helm-operator/tags
```

### Config Private repo 
If you are using a private git repo, then you need to perform one more tasoc to close the loop: you need to add the public key that was generated by flux as a Deploy key in the repo.
```sh
az k8s-configuration show --cluster-name $azure_arc_aro --name $arc_config_name_aro -g $aro_rg_name --cluster-type connectedClusters --query 'repositoryPublicKey'
```

### Validate the Kubernetes configuration
```sh
oc get ns --show-labels
oc -n team-a get cm -o yaml
oc -n itops get all
oc get ep -n gitops
oc get events
flux_logs_agent_pod=$(oc get po -l app.kubernetes.io/component=flux-logs-agent -n $azure_arc_ns -o jsonpath={.items[0].metadata.name})
oc logs $flux_logs_agent_pod -c flux-logs-agent -n $azure_arc_ns 
# az k8s-configuration delete --name '<config name>' -g '<resource group name>' --cluster-name '<cluster name>' --cluster-type connectedClusters
helm ls

# clean-up
oc delete ns team-a
oc delete ns team-b
oc delete ns team-g
oc delete ns itops
oc delete deployment azure-vote-front
oc delete deployment azure-vote-back
oc delete svc azure-vote-back
oc delete svc azure-vote-front

oc delete svc hello-server

```


## Deploy applications using Helm and GitOps

You can learn more about the HelmRelease in the official [Helm Operator documentation](https://docs.fluxcd.io/projects/helm-operator/en/stable/references/helmrelease-custom-resource)

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-with-helm](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-with-helm)

```sh

az k8s-configuration create --name "$arc_config_name_aro-azure-voting-app" --cluster-name $azure_arc_aro -g $aro_rg_name \
  --operator-instance-name "$arc_operator_instance_name_aro-azure-voting-app" \
  --operator-namespace prod \
  --enable-helm-operator \
  --helm-operator-version='0.6.0' \
  --helm-operator-params='--set helm.versions=v3' \
  --repository-url $gitops_helm_url \
  --operator-params='--git-readonly --git-path=releases/prod' \
  --scope namespace \
  --cluster-type connectedClusters

az k8s-configuration show --resource-group $aro_rg_name --name "$arc_config_name_aro-azure-voting-app" --cluster-name $azure_arc_aro --cluster-type connectedClusters

# notices the new Pending configuration
complianceState=$(az k8s-configuration show --cluster-name $azure_arc_aro --name "$arc_config_name_aro-azure-voting-app" -g $aro_rg_name --cluster-type connectedClusters --query 'complianceStatus.complianceState')
echo "Compliance State " : $complianceState

# Verify the App
oc get ns | grep -i "prod"
oc get po -n prod

oc top pods
oc top node # verify CPU < 10%
oc get events -A

for n in $(oc get nodes -o=custom-columns=:.metadata.name)
do
  oc describe node $n # you verify if CPU request is around 100%
done

# https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#how-pods-with-resource-requests-are-scheduled
# When you create a Pod, the Kubernetes scheduler selects a node for the Pod to run on. Each node has a maximum capacity for each of the resource types: the amount of CPU and memory it can provide for Pods. The scheduler ensures that, for each resource type, the sum of the resource requests of the scheduled Containers is less than the capacity of the node. Note that although actual memory or CPU resource usage on nodes is very low, the scheduler still refuses to place a Pod on a node if the capacity checoc fails. This protects against a resource shortage on a node when resource usage later increases, for example, during a daily peaoc in request rate

# Yoy might see the vote-front-azure-vote-app Pod in PENDING status 
# FailedScheduling : 0/3 nodes are available: 3 Insufficient cpu
#   Limits:
#      cpu:  500m
#    Requests:
#      cpu:  250m

# https://cloud.google.com/kubernetes-engine/docs/troubleshooting#PodUnschedulable
# https://stackoverflow.com/questions/47269602/how-do-i-avoid-unschedulable-pods-when-running-an-autoscale-enabled-google-conta
# https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/

# aro has a default LimitRange with default limits for CPU request set to 100m. aro has a default LimitRange with default limits for CPU request set to 100m
# This limit is applied to every container
oc get limitrange -o=yaml -n prod


for pod in $(oc get po -l app=vote-front-azure-vote-app -n prod -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^vote-front-azure-vote-app.*" ]] 
    then
      echo "Verifying Pod $pod"
      oc describe pod $pod -n prod
      oc logs $pod -n prod # | grep -i "Error"
      # oc exec $pod -n prod -it -- /bin/sh
  fi
done


oc get svc/azure-vote-front -n prod -o yaml
oc describe svc/azure-vote-front -n prod


# https://cloud.google.com/kubernetes-engine/docs/how-to/exposing-apps#creating_a_service_of_type_nodeport
# azure_vote_front_port=$(oc get svc/azure-vote-front -n prod -o jsonpath="{.spec.ports[0].nodePort}")
# gcloud compute firewall-rules create test-node-port --allow tcp:node-port

azure_vote_front_url=$(oc get svc/azure-vote-front -n prod -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

# Find the external IP address from the output above and open it in a browser.
echo "Open your brower to test the App at http://$azure_vote_front_url"


# Cleanup
az k8s-configuration delete --name "$arc_config_name_aro-azure-voting-app" --cluster-name $azure_arc_aro --cluster-type connectedClusters -g $aro_rg_name
oc delete ns prod

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
az policy definition create --name "aro-gitops-enforcement"
                            --description "Ensure to deploy GitOps to Kubernetes cluster"
                            --display-name "aro-gitops-enforcement"
                            [--management-group]
                            [--metadata]
                            [--mode]
                            --params --git-poll-interval=1m
                            [--rules]
                            [--subscription]

az policy assignment list -g $aro_rg_name
az policy assignment list -g $aro_rg_name
gitOpsAssignmentId=$(az policy assignment show --name xxx -g $aro_rg_name --query id)

# Create a remediation for a specific assignment
az policy remediation start ...
# Start-AzPolicyRemediation -Name 'myRemedation' -PolicyAssignmentId $gitOpsAssignmentId # '/subscriptions/${subId}/providers/Microsoft.Authorization/policyAssignments/${gitOpsAssignmentId}'

```


## Monitor a connected cluster with Azure Monitor for containers

See :
- [https://aka.ms/arc-k8s-ci-onboarding](https://aka.ms/arc-k8s-ci-onboarding)

### Pre-req
See the [doc](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-enable-arc-enabled-clusters#prerequisites)

- To enable and access the features in Azure Monitor for containers, at a minimum you need to be a member of the Azure Contributor role in the Azure subscription, and a member of the Log Analytics Contributor role of the Log Analytics workspace configured with Azure Monitor for containers.
- You are a member of the Contributor role on the Azure Arc cluster resource.
- To view the monitoring data, you are a member of the Log Analytics reader role permission with the Log Analytics workspace configured with Azure Monitor for containers.
- 

### Setup

<span style="color:red">/!\ IMPORTANT </span> : The same analytics workspace is shared for all k8s clusters, do not recreate it if it was already created in previous use case.

```sh
az monitor log-analytics workspace list
az monitor log-analytics workspace create -n $analytics_workspace_name --location $location -g $aro_rg_name --verbose
az monitor log-analytics workspace list
az monitor log-analytics workspace show -n $analytics_workspace_name -g $aro_rg_name --verbose

export analytics_workspace_id=$(az monitor log-analytics workspace show -n $analytics_workspace_name -g $aro_rg_name -o tsv --query id)
echo "analytics_workspace_id:" $analytics_workspace_id

# https://github.com/Azure/azure-cli/issues/8401 --query id ==> -o tsv is NECESSARY
export azureArc_aro_ClusterResourceId=$(az connectedk8s show -g $aro_rg_name --name $azure_arc_aro --query id -o tsv)

oc config use-context $kubeContext
oc config get-contexts
oc config view --minify
oc config current-context

# curl -o enable-monitoring.sh -L https://aka.ms/enable-monitoring-bash-script
# bash enable-monitoring.sh --resource-id $azureArc_aro_ClusterResourceId --workspace-id $analytics_workspace_id --kube-context $kubeContext

az k8s-extension create --name azuremonitor-containers --cluster-name $aro_cluster_name --resource-group $aro_rg_name --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers --configuration-settings logAnalyticsWorkspaceResourceID=$analytics_workspace_id omsagent.resources.daemonset.limits.cpu=150m omsagent.resources.daemonset.limits.memory=600Mi omsagent.resources.deployment.limits.cpu=1 omsagent.resources.deployment.limits.memory=750Mi

az k8s-extension list --cluster-name $aro_cluster_name --resource-group $aro_rg_name --cluster-type connectedClusters 
azmon_extension_state=$(az k8s-extension show --name azuremonitor-containers --cluster-name $aro_cluster_name --resource-group $aro_rg_name --cluster-type connectedClusters --query 'installState')
echo "Azure Monitor extension state: " $azmon_extension_state


```
Verify :

- After you've enabled monitoring, it might take about 15 minutes before you can view health metrics for the cluster.
- By default, the containerized agent collects the stdout/ stderr container logs of all the containers running in all the namespaces except kube-system. To configure container log collection specific to particular namespace or namespaces, review [Container Insights agent configuration](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-agent-config) to configure desired data collection settings to your ConfigMap configurations file.
- To learn how to stop monitoring your Arc enabled Kubernetes cluster with Azure Monitor for containers, see [How to stop monitoring your hybrid cluster](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-optout-hybrid#how-to-stop-monitoring-on-arc-enabled-kubernetes).

### Clean-Up
```sh
curl -o disable-monitoring.sh -L https://aka.ms/disable-monitoring-bash-script
bash disable-monitoring.sh --resource-id $azureArc_aro_ClusterResourceId --kube-context $kubeContext
```

## Manage Kubernetes policy within a connected cluster with Azure Policy for Kubernetes

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

# Policy Insights Data Writer : Role-ID 66bb4e9e-b016-4a94-8249-4c0511c2be84
az role assignment create \
     --role 66bb4e9e-b016-4a94-8249-4c0511c2be84 \
     --assignee $aro_sp_id \
    --scope /subscriptions/$subId

helm search repo azure-policy

# In below command, replace the following values with those gathered above.
#    <AzureArcClusterResourceId> with your Azure Arc enabled Kubernetes cluster resource Id. For example: /subscriptions/<subscriptionId>/resourceGroups/<rg>/providers/Microsoft.Kubernetes/connectedClusters/<clusterName>
#    <ServicePrincipalAppId> with app Id of the service principal created during prerequisites.
#    <ServicePrincipalPassword> with password of the service principal created during prerequisites.
#    <ServicePrincipalTenantId> with tenant of the service principal created during prerequisites.
helm install azure-policy-addon azure-policy/azure-policy-addon-arc-clusters \
    --set azurepolicy.env.resourceid=$azureArc_aro_ClusterResourceId \
    --set azurepolicy.env.clientid=$aro_sp_id \
    --set azurepolicy.env.clientsecret=$aro_sp_password \
    --set azurepolicy.env.tenantid=$tenantId

helm ls
# azure-policy pod is installed in kube-system namespace
oc get pods -n kube-system

# gatekeeper pod is installed in gatekeeper-system namespace
oc get pods -n gatekeeper-system

# Get the Azure-Policy pod name installed in kube-system namespace
# -l app=azure-policy-webhoooc 
for pod in $(oc get po -l app=azure-policy -n kube-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^azure-policy.*" ]]
    then
      echo "Verifying Azure-Policy Pod $pod"
      # oc describe pod $pod -n kube-system
      oc logs $pod -n kube-system # | grep -i "Error"
      # oc exec $pod -n kube-system -it -- /bin/sh
  fi
done

# Get the GateKeeper pod name installed in gatekeeper-system namespace
for pod in $(oc get po -l gatekeeper.sh/system=yes -n gatekeeper-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^gatekeeper.*" ]]
    then
      echo "Verifying GateKeeper Pod $pod"
      # oc describe pod $pod -n gatekeeper-system
      oc logs $pod -n gatekeeper-system  | grep -i "Error"
      # oc exec $pod -n gatekeeper-system -it -- /bin/sh
  fi
done

```
[Assign a built-in policy definition](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes?toc=/azure/azure-arc/kubernetes/toc.json#assign-a-built-in-policy-definition)

Ex: "Preview: Do not allow [privileged containers](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) in Kubernetes cluster"
By default, Docker containers are “unprivileged” and cannot, for example, run a Docker daemon inside a Docker container. This is because by default a container is not allowed to access any devices, but a “privileged” container is given access to all devices (see the documentation on cgroups devices).

When the operator executes docker run --privileged, Docker will enable access to all devices on the host as well as set some configuration in AppArmor or SELinux to allow the container nearly all the same access to the host as processes running outside containers on the host.

See also this [blog](https://blog.trailofbits.com/2019/07/19/understanding-docker-container-escapes)

Wait for a few minutes and checoc the logs :

```sh

oc get ns

for pod in $(oc get po -l app=azure-policy -n kube-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^azure-policy.*" ]]
    then
      echo "Verifying Azure-Policy Pod $pod"
      oc logs $pod -n kube-system # | grep -i "Error"
  fi
done

for pod in $(oc get po -l gatekeeper.sh/system=yes -n gatekeeper-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^gatekeeper.*" ]]
    then
      echo "Verifying GateKeeper Pod $pod"
      oc logs $pod -n gatekeeper-system  # | grep -i "Error"
  fi
done

oc get crds
# oc get configs.config.gatekeeper.sh -n gatekeeper-system
# oc describe configs.config.gatekeeper.sh -n gatekeeper-system

container_no_privilege_constraint=$(oc get k8sazurecontainernoprivilege.constraints.gatekeeper.sh -n gatekeeper-system -o jsonpath="{.items[0].metadata.name}")
oc describe k8sazurecontainernoprivilege.constraints.gatekeeper.sh $container_no_privilege_constraint -n gatekeeper-system

# Try to deploy a "bad" Pod
oc apply -f app/root-pod.yaml

# You should see the error below
Error from server ([denied by azurepolicy-container-no-privilege-dc2585889397ecb73d135643b3e0e0f2a6da54110d59e676c2286eac3c80dab5] Privileged container is not allowed: root-demo, securityContext: {"privileged": true}): error when creating "root-demo-pod.yaml": admission webhoooc "validation.gatekeeper.sh" denied the request: [denied by azurepolicy-container-no-privilege-dc2585889397ecb73d135643b3e0e0f2a6da54110d59e676c2286eac3c80dab5] Privileged container is not allowed: root-demo, securityContext: {"privileged": true}


```

## IoT Edge workloads integration

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/deploy-azure-iot-edge-workloads](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/deploy-azure-iot-edge-workloads)

```sh

```

## Enforce threat protection using Azure Defender

See [Defend Azure Arc enabled Kubernetes clusters running in on-premises and multi-cloud environments](https://docs.microsoft.com/en-us/azure/security-center/defender-for-kubernetes-azure-arc?toc=%2Fazure%2Fazure-arc%2Fkubernetes%2Ftoc.json&tabs=k8s-deploy-asc%2Ck8s-verify-asc%2Ck8s-remove-arc)

```sh
az k8s-extension create --name microsoft.azuredefender.kubernetes --cluster-type connectedClusters --cluster-name $azure_arc_aro -g $aro_rg_name --extension-type microsoft.azuredefender.kubernetes --config logAnalyticsWorkspaceResourceID=$analytics_workspace_id --config auditLogPath=/var/log/kube-apiserver/audit.log

# verify
az k8s-extension show --cluster-type connectedClusters --cluster-name $azure_arc_aro -g $aro_rg_name --name microsoft.azuredefender.kubernetes

kubectl get pods -n azuredefender

#test: he expected response is "No resource found".
# Within 30 minutes, Azure Defender will detect this activity and trigger a security alert.
kubectl get pods --namespace=asc-alerttest-662jfi039n

```

## Deploy Arc enabled Open Service Mesh

See [Azure Arc-enabled Open Service Mesh](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-arc-enabled-open-service-mesh)

Following Kubernetes distributions are currently supported
- AKS Engine
- Cluster API Azure
- Google Kubernetes Engine
- Canonical Kubernetes Distribution
- Rancher Kubernetes Engine
- OpenShift Kubernetes Distribution
- Amazon Elastic Kubernetes Service

Azure Monitor integration with Azure Arc enabled Open Service Mesh is available with limited support.

```sh
export VERSION=0.8.4

cat <<EOF >> deploy/osm_openshift_settings.json
{
    "osm.OpenServiceMesh.enablePrivilegedInitContainer": "true"
}
EOF

cat deploy/osm_openshift_settings.json
export SETTINGS_FILE=deploy/osm_openshift_settings.json

az k8s-extension create --cluster-name $azure_arc_aro -g $aro_rg_name --cluster-type connectedClusters --extension-type Microsoft.openservicemesh --scope cluster --release-train pilot --name osm --version $VERSION --configuration-settings-file $SETTINGS_FILE

oc adm policy add-scc-to-user privileged -z <service account name> -n <service account namespace>

```



## Troubleshooting

See [Azure Arc doc](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/troubleshooting)






# Clean-Up
```sh

export KUBECONFIG=~/.kube/config
aro_ctx=$(sudo cat $KUBECONFIG | grep -i "name: default")
ctx_length=$(echo -e $aro_ctx | wc -c)
export kubeContext="${aro_ctx:8:$ctx_length}"

helm uninstall azure-policy-addon

az k8s-configuration delete --name "$arc_config_name_aro-azure-voting-app" --cluster-name $azure_arc_aro --cluster-type connectedClusters -g $aro_rg_name -y
az k8s-configuration delete --name $arc_config_name_aro --cluster-name $azure_arc_aro --cluster-type connectedClusters -g $aro_rg_name -y

az policy definition delete --name "aro-gitops-enforcement"
az policy assignment delete --name xxx -g $aro_rg_name

# curl -o disable-monitoring.sh -L https://aka.ms/disable-monitoring-bash-script
# bash disable-monitoring.sh --resource-id $azureArc_aro_ClusterResourceId --kube-context $kubeContext
# az monitor log-analytics workspace delete --workspace-name $analytics_workspace_name -g $aro_rg_name

az k8s-extension delete --name azuremonitor-containers --cluster-type connectedClusters --cluster-name $aro_cluster_name  -g $aro_rg_name
az k8s-extension delete --cluster-type connectedClusters --cluster-name $azure_arc_aro -g $aro_rg_name --name microsoft.azuredefender.kubernetes --yes
az k8s-extension delete --cluster-type connectedClusters --cluster-name $azure_arc_aro -g $aro_rg_name --name microsoft.azuredefender.kubernetes --yes

az connectedk8s delete --name $azure_arc_aro -g $aro_rg_name -y

az aro delete --name $aro_cluster_name -g $aro_rg_name -y

