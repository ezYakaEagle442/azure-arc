See :
- [https://github.com/microsoft/azure_arc/tree/main/azure_arc_k8s_jumpstart/eks/terraform](https://github.com/microsoft/azure_arc/tree/main/azure_arc_k8s_jumpstart/eks/terraform)
- [https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)

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


# Setup EKS Cluster
```sh
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/resource-groups/create-group.html
# https://docs.aws.amazon.com/cli/latest/reference/resource-groups/create-group.html

aws resource-groups create-group --name rg-arc-eks --configuration xxx


# https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html
# https://aws.amazon.com/ec2/instance-types


eksctl create cluster --help

# add AmazonSSMFullAccess + AWSCloudFormationFullAccess + IAMFullAccess + AdministratorAccess iam:CreateRole to IAM
AmazonEC2FullAccess
AmazonEKSClusterPolicy
AmazonEKSWorkerNodePolicy
AmazonEC2ContainerRegistryFullAccess
AmazonSSMFullAccess
AmazonEKSServicePolicy
ResourceGroupsandTagEditorFullAccess
AmazonEKS_CNI_Policy
AWSCloudFormationFullAccess
AmazonEKSVPCResourceController

# underscore "_" is denied : https://github.com/weaveworks/eksctl/issues/2943
# Member must satisfy regular expression pattern: [a-zA-Z][-a-zA-Z0-9]*
eksctl create cluster \
  --name $EKS_PROJECT \
  --version 1.19 \
  --region $EKS_REGION \
  --zones eu-west-3a,eu-west-3b,eu-west-3c \
  --nodegroup-name MC-arc-eks-101 \
  --node-ami-family AmazonLinux2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --node-type t2.large \
  --enable-ssm \
  --full-ecr-access \
  --alb-ingress-access
  # --with-oidc \
  # --dry-run

# https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
ll ~/.kube/config
cat ~/.kube/config

k config view --minify
k config get-contexts
# aws eks --region $EKS_REGION update-kubeconfig --name $EKS_PROJECT
k cluster-info
k get svc

# Deploy a dummy app: https://github.com/paulbouwer/hello-kubernetes & https://hub.docker.com/r/paulbouwer/hello-kubernetes
# liorkamrat/hello-arc | https://github.com/ezYakaEagle442/hello_arc
k create deployment hello-server --image=liorkamrat/hello-arc #paulbouwer/hello-kubernetes:1.10
k expose deployment hello-server --type LoadBalancer --port 80 --target-port 8080

k get pods
k get service hello-server -o wide

# # https://cloud.google.com/kubernetes-engine/docs/how-to/exposing-apps#creating_a_service_of_type_loadbalancer
eks_hello_svc_lb=$(k get svc hello-server -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
echo "Test from your browser : http://$eks_hello_svc_lb"

# clean-up
k delete deployment hello-server
k delete svc hello-server
```


## Register to Azure Arc.

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster)
```sh

azure_arc_ns="azure-arc"

# Deploy Azure Arc Agents for Kubernetes using Helm 3, into the azure-arc namespace
az connectedk8s connect --name $azure_arc_eks --infrastructure aws -l $location -g $eks_rg_name

# verify
az connectedk8s list --subscription $subId -o table
az connectedk8s list -g $eks_rg_name -o table # -c $azure_arc_eks --cluster-type connectedClusters 

# -o tsv is MANDATORY to remove quotes
azure_arc_eks_id=$(az connectedk8s show --name $azure_arc_eks -g $eks_rg_name -o tsv --query id)

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


```


## Enable GitOps on a connected cluster

See [https://aka.ms/AzureArcK8sUsingGitOps](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-connected-cluster)

### Create Config for GitOps workflow

Fork this [sample repo](https://github.com/Azure/arc-k8s-demo) into your GitHub account 

```sh

git clone $gitops_url

k create namespace $arc_gitops_namespace

# https://docs.fluxcd.io/en/1.17.1/faq.html#will-flux-delete-resources-when-i-remove-them-from-git
# Will Flux delete resources when I remove them from git?
# Flux has an garbage collection feature, enabled by passing the command-line flag --sync-garbage-collection to fluxd
az k8s-configuration create --name $arc_config_name_eks --cluster-name $azure_arc_eks -g $eks_rg_name --cluster-type connectedClusters \
  --repository-url $gitops_url \
  --enable-helm-operator true \
  --helm-operator-params '--set helm.versions=v3' \
  --operator-namespace $arc_gitops_namespace \
  --operator-instance-name $arc_operator_instance_name_eks \
  --operator-type flux \
  --operator-params='--git-poll-interval=1m --sync-garbage-collection' \
  --scope cluster # namespace

az k8s-configuration list --cluster-name $azure_arc_eks -g $eks_rg_name --cluster-type connectedClusters
az k8s-configuration show --cluster-name $azure_arc_eks --name $arc_config_name_eks -g $eks_rg_name --cluster-type connectedClusters

repositoryPublicKey=$(az k8s-configuration show --cluster-name $azure_arc_eks --name $arc_config_name_eks -g $eks_rg_name --cluster-type connectedClusters --query 'repositoryPublicKey')
echo "repositoryPublicKey : " $repositoryPublicKey
echo "Add this Public Key to your GitHub Project Deploy Key and allow write access at https://github.com/$github_usr/arc-k8s-demo/settings/keys"

echo "If you forget to add the GitHub SSH Key, you will see in the GitOps pod the error below : "
echo "Permission denied (publickey). fatal: Could not read from remote repository.\n\nPlease make sure you have the correct access rights nand the repository exists."

# troubleshooting: 
for pod in $(k get po -L app=helm-operator -n $arc_gitops_namespace -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"=~"^$arc_operator_instance_name_eks*" ]]
    then
      echo "Verifying GitOps config Pod $pod"
      k logs $pod -n $arc_gitops_namespace | grep -i "Error"
      k logs $pod -n $arc_gitops_namespace | grep -i "Permission denied (publickey)"
  fi
done


# notices the new Pending configuration
complianceState=$(az k8s-configuration show --cluster-name $azure_arc_eks --name $arc_config_name_eks -g $eks_rg_name --cluster-type connectedClusters --query 'complianceStatus.complianceState')
echo "Compliance State " : $complianceState

git_config=$(k get gitconfigs.clusterconfig.azure.com -n $arc_gitops_namespace -o jsonpath={.items[0].metadata.name})
k describe gitconfigs.clusterconfig.azure.com $git_config -n $arc_gitops_namespace

# https://kubernetes.io/docs/concepts/extend-kubernetes/operator
# https://github.com/fluxcd/helm-operator/blob/master/chart/helm-operator/CHANGELOG.md#060-2020-01-26
k get po -L app=helm-operator -n $arc_gitops_namespace
k describe po eks-cluster-config-helm-gitops-helm-operator-c546b564b-glcf5 -n $arc_gitops_namespace | grep -i "image" # ==> Image: docker.io/fluxcd/helm-operator:1.0.0-rc4
# https://hub.docker.com/r/fluxcd/helm-operator/tags
```

### Config Private repo 
If you are using a private git repo, then you need to perform one more task to close the loop: you need to add the public key that was generated by flux as a Deploy key in the repo.
```sh
az k8s-configuration show --cluster-name $azure_arc_eks --name $arc_config_name_eks -g $eks_rg_name --query 'repositoryPublicKey'
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
# az k8s-configuration delete --name '<config name>' -g '<resource group name>' --cluster-name '<cluster name>' --cluster-type connectedClusters
helm ls

# clean-up
k delete ns team-a
k delete ns team-b
k delete ns team-g
k delete ns itops
k delete deployment azure-vote-front
k delete deployment azure-vote-back
k delete svc azure-vote-back
k delete svc azure-vote-front

k delete svc hello-server

```


## Deploy applications using Helm and GitOps

You can learn more about the HelmRelease in the official [Helm Operator documentation](https://docs.fluxcd.io/projects/helm-operator/en/stable/references/helmrelease-custom-resource)

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-with-helm](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-with-helm)

```sh

az k8s-configuration create --name "$arc_config_name_eks-azure-voting-app" --cluster-name $azure_arc_eks -g $eks_rg_name \
  --operator-instance-name "$arc_operator_instance_name_eks-azure-voting-app" \
  --operator-namespace prod \
  --enable-helm-operator \
  --helm-operator-version='0.6.0' \
  --helm-operator-params='--set helm.versions=v3' \
  --repository-url $gitops_helm_url \
  --operator-params='--git-readonly --git-path=releases/prod' \
  --scope namespace \
  --cluster-type connectedClusters

az k8s-configuration show --resource-group $eks_rg_name --name "$arc_config_name_eks-azure-voting-app" --cluster-name $azure_arc_eks --cluster-type connectedClusters

# notices the new Pending configuration
complianceState=$(az k8s-configuration show --cluster-name $azure_arc_eks --name "$arc_config_name_eks-azure-voting-app" -g $eks_rg_name --cluster-type connectedClusters --query 'complianceStatus.complianceState')
echo "Compliance State " : $complianceState

# Verify the App
k get po -n prod

k top pods
k top node # verify CPU < 10%
k get events -A

for n in $(k get nodes -o=custom-columns=:.metadata.name)
do
  k describe node $n # you verify if CPU request is around 100%
done

# https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#how-pods-with-resource-requests-are-scheduled
# When you create a Pod, the Kubernetes scheduler selects a node for the Pod to run on. Each node has a maximum capacity for each of the resource types: the amount of CPU and memory it can provide for Pods. The scheduler ensures that, for each resource type, the sum of the resource requests of the scheduled Containers is less than the capacity of the node. Note that although actual memory or CPU resource usage on nodes is very low, the scheduler still refuses to place a Pod on a node if the capacity check fails. This protects against a resource shortage on a node when resource usage later increases, for example, during a daily peak in request rate

# Yoy might see the vote-front-azure-vote-app Pod in PENDING status 
# FailedScheduling : 0/3 nodes are available: 3 Insufficient cpu
#   Limits:
#      cpu:  500m
#    Requests:
#      cpu:  250m

k get limitrange -o=yaml -n prod


# ^vote-front-azure-vote-app.*
#!/bin/bash
for pod in $(k get po -l app=vote-front-azure-vote-app -n prod -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^vote-front-azure-vote-app*" ]] 
    then
      echo "Verifying Pod $pod"
      k describe pod $pod -n prod
      k logs $pod -n prod | grep -i "Error"
      k exec $pod -n prod -it -- /bin/sh
  fi
done


k get svc/azure-vote-front -n prod -o yaml
k describe svc/azure-vote-front -n prod


azure_vote_front_url=$(k get svc/azure-vote-front -n prod -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

# Find the external IP address from the output above and open it in a browser.
echo "Open your brower to test the App at http://$azure_vote_front_url"


# Cleanup
az k8s-configuration delete --name "$arc_config_name_eks-azure-voting-app" --cluster-name $azure_arc_eks --cluster-type connectedClusters -g $eks_rg_name
k delete ns prod

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
az policy definition create --name "eks-gitops-enforcement"
                            --description "Ensure to deploy GitOps to Kubernetes cluster"
                            --display-name "eks-gitops-enforcement"
                            [--management-group]
                            [--metadata]
                            [--mode]
                            --params --git-poll-interval=1m
                            [--rules]
                            [--subscription]

az policy assignment list -g $eks_rg_name -g $eks_rg_name

gitOpsAssignmentId=$(az policy assignment show --name xxx -g $eks_rg_name --query id)

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
az monitor log-analytics workspace create -n $analytics_workspace_name --location $location -g $eks_rg_name --verbose
az monitor log-analytics workspace list
az monitor log-analytics workspace show -n $analytics_workspace_name -g $eks_rg_name --verbose

export analytics_workspace_id=$(az monitor log-analytics workspace show -n $analytics_workspace_name -g $eks_rg_name -o tsv --query id)
echo "analytics_workspace_id:" $analytics_workspace_id

k config view --minify
k config get-contexts
export kubeContext="$AWS_ACCOUNT@"$EKS_PROJECT"."$EKS_REGION".eksctl.io" #"<kubeContext name of your k8s cluster>"

# curl -o enable-monitoring.sh -L https://aka.ms/enable-monitoring-bash-script
# bash enable-monitoring.sh --resource-id $azure_arc_eks_id --workspace-id $analytics_workspace_id --kube-context $kubeContext

az k8s-extension create --name azuremonitor-containers --cluster-name $azure_arc_eks --resource-group $eks_rg_name --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers --configuration-settings logAnalyticsWorkspaceResourceID=$analytics_workspace_id omsagent.resources.daemonset.limits.cpu=150m omsagent.resources.daemonset.limits.memory=600Mi omsagent.resources.deployment.limits.cpu=1 omsagent.resources.deployment.limits.memory=750Mi

az k8s-extension list --cluster-name $azure_arc_eks --resource-group $eks_rg_name --cluster-type connectedClusters 
azmon_extension_state=$(az k8s-extension show --name azuremonitor-containers --cluster-name $azure_arc_eks --resource-group $eks_rg_name --cluster-type connectedClusters --query 'installState')
echo "Azure Monitor extension state: " $azmon_extension_state

```
Verify :

- After you've enabled monitoring, it might take about 15 minutes before you can view health metrics for the cluster.
- By default, the containerized agent collects the stdout/ stderr container logs of all the containers running in all the namespaces except kube-system. To configure container log collection specific to particular namespace or namespaces, review [Container Insights agent configuration](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-agent-config) to configure desired data collection settings to your ConfigMap configurations file.
- To learn how to stop monitoring your Arc enabled Kubernetes cluster with Azure Monitor for containers, see [How to stop monitoring your hybrid cluster](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-optout-hybrid#how-to-stop-monitoring-on-arc-enabled-kubernetes).


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

# https://github.com/MicrosoftDocs/azure-docs/issues/57961
az_policy_sp_password=$(az ad sp create-for-rbac --name $appName-eks --role "Policy Insights Data Writer (Preview)" --scopes $azure_arc_eks_id --query password --output tsv)
# az_policy_sp_scope="/subscriptions/$subId/resourceGroups/$eks_rg_name/providers/Microsoft.Kubernetes/connectedClusters/$azure_arc_eks"
# az_policy_sp_password=$(az ad sp create-for-rbac --name $appName-eks --role "Policy Insights Data Writer (Preview)" --scopes $az_policy_sp_scope --query password --output tsv)

echo $az_policy_sp_password > az_policy_eks_sp_password.txt
echo "Azure Policy Service Principal Password saved to ./az_policy_eks_sp_password.txt IMPORTANT Keep your password ..." 
# az_policy_sp_password=`cat az_policy_eks_sp_password.txt`
az_policy_sp_id=$(az ad sp show --id http://$appName-eks --query appId -o tsv)
#az_policy_sp_id=$(az ad sp list --all --query "[?appDisplayName=='${appName-eks}'].{appId:appId}" --output tsv)
#az_policy_sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName-eks}'].{appId:appId}" --output tsv)
echo "Azure Policy Service Principal ID:" $az_policy_sp_id 
echo $az_policy_sp_id > az_policy_eks_sp_id.txt
# az_policy_sp_id=`cat az_policy_eks_sp_id.txt`
az ad sp show --id $az_policy_sp_id

# Policy Insights Data Writer : Role-ID 66bb4e9e-b016-4a94-8249-4c0511c2be84
# az role assignment create \
#     --role 66bb4e9e-b016-4a94-8249-4c0511c2be84 \
#     --assignee $az_policy_sp_id \
#    --scope /subscriptions/$subId

helm search repo azure-policy

# In below command, replace the following values with those gathered above.
#    <AzureArcClusterResourceId> with your Azure Arc enabled Kubernetes cluster resource Id. For example: /subscriptions/<subscriptionId>/resourceGroups/<rg>/providers/Microsoft.Kubernetes/connectedClusters/<clusterName>
#    <ServicePrincipalAppId> with app Id of the service principal created during prerequisites.
#    <ServicePrincipalPassword> with password of the service principal created during prerequisites.
#    <ServicePrincipalTenantId> with tenant of the service principal created during prerequisites.
helm install azure-policy-addon azure-policy/azure-policy-addon-arc-clusters \
    --set azurepolicy.env.resourceid=$azure_arc_eks_id \
    --set azurepolicy.env.clientid=$az_policy_sp_id \
    --set azurepolicy.env.clientsecret=$az_policy_sp_password \
    --set azurepolicy.env.tenantid=$tenantId

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
      k logs $pod -n kube-system | grep -i "denied by azurepolicy"
  fi
done

for pod in $(k get po -l gatekeeper.sh/system=yes -n gatekeeper-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^gatekeeper.*" ]]
    then
      echo "Verifying GateKeeper Pod $pod"
      k logs $pod -n gatekeeper-system  | grep -i "denied admission"
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

az policy assignment list

k get ns

for pod in $(k get po -l app=azure-policy -n kube-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^azure-policy.*" ]]
    then
      echo "Verifying Azure-Policy Pod $pod"
      k logs $pod -n kube-system | grep -i "denied by azurepolicy"
  fi
done

for pod in $(k get po -l gatekeeper.sh/system=yes -n gatekeeper-system -o=custom-columns=:.metadata.name)
do
  if [[ "$pod"="^gatekeeper.*" ]]
    then
      echo "Verifying GateKeeper Pod $pod"
      k logs $pod -n gatekeeper-system  | grep -i "denied admission"
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
# https://github.com/open-policy-agent/gatekeeper/tree/master/library/pod-security-policy/privileged-containers

# Try to deploy a "bad" Pod
k apply -f app/root-pod.yaml

# You should see the error below
Error from server ([denied by azurepolicy-container-no-privilege-dc2585889397ecb73d135643b3e0e0f2a6da54110d59e676c2286eac3c80dab5] Privileged container is not allowed: root-demo, securityContext: {"privileged": true}): error when creating "root-demo-pod.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [denied by azurepolicy-container-no-privilege-dc2585889397ecb73d135643b3e0e0f2a6da54110d59e676c2286eac3c80dab5] Privileged container is not allowed: root-demo, securityContext: {"privileged": true}


```
## Enforce threat protection using Azure Defender

See [Defend Azure Arc enabled Kubernetes clusters running in on-premises and multi-cloud environments](https://docs.microsoft.com/en-us/azure/security-center/defender-for-kubernetes-azure-arc?toc=%2Fazure%2Fazure-arc%2Fkubernetes%2Ftoc.json&tabs=k8s-deploy-asc%2Ck8s-verify-asc%2Ck8s-remove-arc)

Limitations	Azure Arc enabled Kubernetes and the Azure Defender extension don't support managed Kubernetes offerings like Google Kubernetes Engine and Elastic Kubernetes Service

```sh
az k8s-extension create --name microsoft.azuredefender.kubernetes --cluster-type connectedClusters --cluster-name $azure_arc_eks -g $eks_rg_name --extension-type microsoft.azuredefender.kubernetes --config logAnalyticsWorkspaceResourceID=$analytics_workspace_id --config auditLogPath=/var/log/kube-apiserver/audit.log

# verify
az k8s-extension show --cluster-type connectedClusters --cluster-name $azure_arc_eks -g $eks_rg_name --name microsoft.azuredefender.kubernetes

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
export $CLUSTER_NAME=<arc-cluster-name>
export $RESOURCE_GROUP=<resource-group-name>

az k8s-extension create --cluster-name $azure_arc_eks --resource-group $eks_rg_name --cluster-type connectedClusters --extension-type Microsoft.openservicemesh --scope cluster --release-train pilot --name osm --version $VERSION

```

## Deploy an Azure ML model to an Arc connected cluster

See []()

```sh

```

## Create an App Service App on Azure Arc

See the docs :
- [https://docs.microsoft.com/en-us/azure/app-service/quickstart-arc#3-create-an-app](https://docs.microsoft.com/en-us/azure/app-service/quickstart-arc#3-create-an-app)
- [https://docs.microsoft.com/en-us/azure/app-service/manage-create-arc-environment#add-azure-cli-extensions](https://docs.microsoft.com/en-us/azure/app-service/manage-create-arc-environment#add-azure-cli-extensions)

### Create a Log Analytics workspace
[doc](https://docs.microsoft.com/en-us/azure/app-service/manage-create-arc-environment#create-a-log-analytics-workspace)

### Install the App Service extension

[doc](https://docs.microsoft.com/en-us/azure/app-service/manage-create-arc-environment#install-the-app-service-extension)

```sh
extensionName="appservice-ext" # Name of the App Service extension
namespace="appservice-ns" # Namespace in your cluster to install the extension and provision resources
kubeEnvironmentName="<kube-environment-name>" # Name of the App Service Kubernetes environment resource

az k8s-extension create \
    --resource-group  $eks_rg_name \
    --name $extensionName \
    --cluster-type connectedClusters \
    --cluster-name $azure_arc_eks \
    --extension-type 'Microsoft.Web.Appservice' \
    --release-train stable \
    --auto-upgrade-minor-version true \
    --scope cluster \
    --release-namespace $namespace \
    --configuration-settings "Microsoft.CustomLocation.ServiceAccount=default" \
    --configuration-settings "appsNamespace=${namespace}" \
    --configuration-settings "clusterName=${kubeEnvironmentName}" \
    --configuration-settings "loadBalancerIp=${staticIp}" \
    --configuration-settings "keda.enabled=true" \
    --configuration-settings "buildService.storageClassName=default" \
    --configuration-settings "buildService.storageAccessMode=ReadWriteOnce" \
    --configuration-settings "customConfigMap=${namespace}/kube-environment-config" \
    --configuration-settings "envoy.annotations.service.beta.kubernetes.io/azure-load-balancer-resource-group=${aksClusterGroupName}" \
    --configuration-settings "logProcessor.appLogs.destination=log-analytics" \
    --configuration-protected-settings "logProcessor.appLogs.logAnalyticsConfig.customerId=${logAnalyticsWorkspaceIdEnc}" \
    --configuration-protected-settings "logProcessor.appLogs.logAnalyticsConfig.sharedKey=${logAnalyticsKeyEnc}"


```


### Create and manage custom locations
```sh
az extension add --upgrade --yes --name customlocation
az extension remove --name appservice-kube
az extension add --yes --source "https://aka.ms/appsvc/appservice_kube-latest-py2.py3-none-any.whl"


```
## 
```sh

paas_vnext_app_name="arc-dummy-app"
# create an App.
az webapp create \
    --resource-group $eks_rg_name \
    --name  $paas_vnext_app_name \
    --custom-location $customLocationId \
    --runtime 'NODE|12-lts'

# Deploy a dummy App.
git clone https://github.com/Azure-Samples/nodejs-docs-hello-world
cd nodejs-docs-hello-world
zip -r package.zip .
az webapp deployment source config-zip -g $eks_rg_name --name $paas_vnext_app_name --src package.zip

# Get diagnostic logs using Log Analytics
let StartTime = ago(72h);
let EndTime = now();
AppServiceConsoleLogs_CL
| where TimeGenerated between (StartTime .. EndTime)
| where AppName_s =~ "<app-name>"

# Deploy a custom container
az webapp create 
    --resource-group $eks_rg_name \
    --name $paas_vnext_app_name \
    --custom-location $customLocationId \
    --deployment-container-image-name mcr.microsoft.com/appsvc/node:12-lts


```



## IoT Edge workloads integration

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/deploy-azure-iot-edge-workloads](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/deploy-azure-iot-edge-workloads)

```sh

```

## Troubleshooting

See [Azure Arc doc](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/troubleshooting)

# Clean-Up
```sh

export KUBECONFIG=eks-config
k config view --minify
k config get-contexts

export kubeContext="eks_"$EKS_PROJECT_ID"_"$EKS_ZONE"_"$EKS_PROJECT
k config use-context $kubeContext

helm uninstall azure-policy-addon

# curl -o disable-monitoring.sh -L https://aka.ms/disable-monitoring-bash-script
# bash disable-monitoring.sh --resource-id $azure_arc_eks_id --kube-context $kubeContext
# az monitor log-analytics workspace delete --workspace-name $analytics_workspace_name -g $eks_rg_name
az k8s-extension delete --name azuremonitor-containers --cluster-type connectedClusters --cluster-name $eks_cluster_name  -g $eks_rg_name

az k8s-configuration delete --name "$arc_config_name_eks-azure-voting-app" --cluster-name $azure_arc_eks --cluster-type connectedClusters -g $eks_rg_name -y
az k8s-configuration delete --name $arc_config_name_eks --cluster-name $azure_arc_eks --cluster-type connectedClusters -g $eks_rg_name -y

az policy definition delete --name "eks-gitops-enforcement" -g $eks_rg_name
az policy assignment delete --name xxx -g $eks_rg_name

az connectedk8s delete --name $azure_arc_eks -g $eks_rg_name -y

aws resource-groups delete-group --group-name rg-arc-eks
eksctl delete cluster -n  $azure_arc_eks --region $EKS_REGION --force

#TODO : delete AWS auto-scaling group + EC2 VM
# https://docs.aws.amazon.com/cli/latest/reference/autoscaling/delete-auto-scaling-group.html

aws delete delete-auto-scaling-group --auto-scaling-group-name <value> --force-delete

```