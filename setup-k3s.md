See :
- [https://github.com/rancher/k3s](https://github.com/rancher/k3s)
- [https://rancher.com/docs/k3s](https://rancher.com/docs/k3s/latest/en/)
- [https://github.com/likamrat/azure_arc/blob/master/azure_arc_k8s_jumpstart/docs/rancher_k3s_azure_arm_template.md](https://github.com/likamrat/azure_arc/blob/master/azure_arc_k8s_jumpstart/docs/rancher_k3s_azure_arm_template.md)
- [https://github.com/likamrat/azure_arc/blob/master/azure_arc_k8s_jumpstart/rancher_k3s/azure/arm_template/scripts/install_k3s.sh](https://github.com/likamrat/azure_arc/blob/master/azure_arc_k8s_jumpstart/rancher_k3s/azure/arm_template/scripts/install_k3s.sh)

# Setup K3S

### Setup NSG 
```sh

k3s_nsg="k3s-nsg-management"
az network nsg create --name $k3s_nsg -g $k3s_rg_name --location $location

az network nsg rule create --access Allow --destination-port-range 22 --source-address-prefixes Internet --name "Allow SSH from Internet" --nsg-name $k3s_nsg -g $k3s_rg_name --priority 100

az network nsg rule create --access Allow --destination-port-range 6443 --source-address-prefixes Internet --name "Allow 6443 from Internet" --nsg-name $k3s_nsg -g $k3s_rg_name --priority 110

az network nsg rule create --access Allow --destination-port-range 80 --source-address-prefixes Internet --name "Allow 80 from Internet" --nsg-name $k3s_nsg -g $k3s_rg_name --priority 120

az network nsg rule create --access Allow --destination-port-range 8080 --source-address-prefixes Internet --name "Allow 8080 from Internet" --nsg-name $k3s_nsg -g $k3s_rg_name --priority 130

az network vnet subnet update --name ManagementSubnet --network-security-group $k3s_nsg --vnet-name $k3s_vnet_name -g $k3s_rg_name

```


## Create Azure LB
```sh
az network public-ip create --resource-group $k3s_rg_name --name $k3s_lb_pub_ip --sku "Standard"

k3s_lb_pub_ip_id=$(az network public-ip show -n $k3s_lb_pub_ip -g $k3s_rg_name --query "id" -o tsv)
echo "k3s_lb_pub_ip_id " $k3s_lb_pub_ip_id

k3s_lb_pub_ip_address=$(az network public-ip show -n $k3s_lb_pub_ip -g $k3s_rg_name --query "ipAddress" -o tsv)
echo "k3s_lb_pub_ip_address" $k3s_lb_pub_ip_address

az network lb create \
--resource-group $k3s_rg_name \
--name $k3s_lb \
--sku standard \
--public-ip-address $k3s_lb_pub_ip \
--frontend-ip-name k3sFrontEnd \
--backend-pool-name k3sBackEndPool

az network lb probe create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3sHealthProbe \
--protocol tcp \
--port 80

az network lb rule create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3sHTTP \
--protocol tcp \
--frontend-port 80 \
--backend-port 80 \
--frontend-ip-name k3sFrontEnd \
--backend-pool-name k3sBackEndPool \
--probe-name k3sHealthProbe

az network lb rule create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3sHTTPS \
--protocol tcp \
--frontend-port 443 \
--backend-port 443 \
--frontend-ip-name k3sFrontEnd \
--backend-pool-name k3sBackEndPool \
--probe-name k3sHealthProbe

az network lb rule create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3sAPI \
--protocol tcp \
--frontend-port 6443 \
--backend-port 6443 \
--frontend-ip-name k3sFrontEnd \
--backend-pool-name k3sBackEndPool \
--probe-name k3sHealthProbe


```

## Create Azure VM

```sh

az network nic create --name nic-k3s --vnet-name $k3s_vnet_name --subnet $k3s_subnet_name --network-security-group $k3s_nsg --public-ip-address $k3s_lb_pub_ip --lb-name $k3s_lb --lb-address-pools k3sBackEndPool -g $k3s_rg_name

az vm create --name $k3s_vm_name \
    --image UbuntuLTS \
    --admin-username $k3s_admin_username \
    --resource-group $k3s_rg_name \
    --vnet-name $k3s_vnet_name \
    --subnet $k3s_subnet_name \
    --nics nic-k3s \
    --nsg $k3s_nsg \
    --size Standard_B2s \
    --location $location \
    --ssh-key-values ~/.ssh/$ssh_key.pub

k3s_network_interface_id=$(az vm show --name $k3s_vm_name -g $k3s_rg_name --query 'networkProfile.networkInterfaces[0].id' -o tsv)
echo "Bastion VM Network Interface ID :" $k3s_network_interface_id

k3s_network_interface_private_ip=$(az resource show --ids $k3s_network_interface_id \
  --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
echo "Network Interface private IP :" $k3s_network_interface_private_ip

k3s_network_interface_pub_ip_id=$(az resource show --ids $k3s_network_interface_id \
  --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.publicIPAddress.id' -o tsv)

k3s_network_interface_pub_ip=$(az network public-ip show -g $k3s_rg_name --id $k3s_network_interface_pub_ip_id --query "ipAddress" -o tsv)
echo "Network Interface public  IP :" $k3s_network_interface_pub_ip

# test
ssh -i ~/.ssh/$ssh_key $k3s_admin_username@$k3s_network_interface_pub_ip

sudo apt update
sudo apt upgrade
sudo apt  install jq

```
[Install AZ CLI in VM](tools.md)
[Install HELM in VM](tools.md#how-to-install-helm-on-ubuntu-or-wsl)
[Configure HELM in VM](setup-helm.md)

## Create K3S

```sh

# Installing k3s to /usr/local/bin/k3s
curl -sfL https://get.k3s.io | sh -
# wget -q -O - https://raw.githubusercontent.com/rancher/k3s/master/install.sh | sh -
sudo service k3s status
k3s --version

sudo ls -al /usr/local/bin/k3s

# A kubeconfig file is written to /etc/rancher/k3s/k3s.yaml

k3s help

alias k="sudo k3s kubectl"
source <(k completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(k completion bash)" >> ~/.bashrc 
complete -F __start_kubectl k

k config view

# sudo k3s server --disable-agent  --token k3stoktoktok --flannel-backend=none & 
# sudo k3s server --cluster-cidr “10.42.0.0/24” --service-cidr “10.43.0.0/24” --cluster-dns “10.43.0.10” --token k3stoktoktok &

sudo ls -al /var/lib/rancher/k3s/server

k version
k get nodes
k get deploy -A
k get pods -A

k get svc -A
k get ing -A

# Check at https://localhost:6443 | https://$k3s_network_interface_pub_ip:6443
token_secret_value=`sudo cat /var/lib/rancher/k3s/server/node-token`

k3s_usr=$(k config view -o json | jq -Mr '.users[0].user.username')
k3s_pwd=$(k config view -o json | jq -Mr '.users[0].user.password')
echo "K3S User " $k3s_usr
echo "K3S PWD " $k3s_pwd

# curl -k https://localhost:6443/api/v1/namespaces -H "Authorization: Bearer $token_secret_value" -H 'Accept: application/json'
curl -k https://localhost:6443/api/v1/namespaces  --user $k3s_usr:$k3s_pwd -H 'Accept: application/json'

# export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo cp /etc/rancher/k3s/k3s.yaml /home/$k3s_admin_username/.kube/config

sudo chown $k3s_admin_username:$k3s_admin_username /home/$k3s_admin_username/.kube/config
ls -al /home/$k3s_admin_username/.kube
export KUBECONFIG=/home/$k3s_admin_username/.kube/config

helm ls -A

# Optional Play with Annotations:
k get pod POD_NAME -o jsonpath='{.metadata.annotations}'
k get deploy myapp -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}'

for node in $(k get nodes -o=custom-columns=':.metadata.name')
do 
	for ano in $(k get node $node -o jsonpath='{.metadata.annotations}')
	do echo $ano
	done
done
```

### Optionnaly create a NEW VM with a K3S agent

See [https://rancher.com/docs/k3s/latest/en/installation/install-options/agent-config](https://rancher.com/docs/k3s/latest/en/installation/install-options/agent-config)
After the VM install, compplete previous steps above (AZ, HELM & K3S setup)

```sh
az vm create --name "$k3s_vm_name-agent" \
    --image UbuntuLTS \
    --admin-username $k3s_admin_username \
    --resource-group $k3s_rg_name \
    --vnet-name $k3s_vnet_name \
    --subnet $k3s_subnet_name \
    --nsg $k3s_nsg \
    --size Standard_B2s \
    --location $location \
    --ssh-key-values ~/.ssh/$ssh_key.pub

# Get the IP
# ip addr show eth0 | grep inet | cut -d / -f1
# ifconfig -a
# hostname -I
# host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has address"
# myip=$(curl icanhazip.com)
# myip=$(dig +short myip.opendns.com @resolver1.opendns.com)
# cluster_internal_ip=$(k get nodes -o jsonpath="{.items[0].status.addresses[0].address}")

ipconf=$(ip addr show eth0 | grep inet | cut -d / -f1)
cluster_internal_ip="${ipconf:9:13}"
# NODE_TOKEN comes from /var/lib/rancher/k3s/server/node-token on your server
NODE_TOKEN=`sudo cat /var/lib/rancher/k3s/server/node-token`
sudo k3s agent --server https://$cluster_internal_ip:6443 --node-ip $cluster_internal_ip --token $NODE_TOKEN # --flannel-backend=none

```


## Deploy a dummy App.

Traefik is the (default) Ingress controller for k3s and uses port 80. To test external access to k3s cluster, deploy an ["hello-world"](https://github.com/paulbouwer/hello-kubernetes) App.
Since port 80 is taken by Traefik (read more about here), the deployment LoadBalancer was changed to use port **32380** along side with the matching Azure Network Security Group (NSG).

```sh
k apply -f app/hello hello-kubernetes.yaml
hello_svc_cluster_ip=$(k get svc hello-kubernetes -o=custom-columns=":spec.clusterIP")
curl http://$hello_svc_cluster_ip:32380

echo "Test from your browser : http://$k3s_network_interface_pub_ip/hello-kubernetes "


k get deploy
k get po


```

## Register to Azure Arc.

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster)
```sh

azure_arc_ns="azure-arc"

# Deploy Azure Arc Agents for Kubernetes using Helm 3, into the azure-arc namespace
az connectedk8s connect --name $azure_arc_k3s  -l $location -g $k3s_rg_name
k get crds
k get azureclusteridentityrequests.clusterconfig.azure.com -n $azure_arc_ns
k describe azureclusteridentityrequests.clusterconfig.azure.com config-agent-identity-request -n $azure_arc_ns

k get connectedclusters.arc.azure.com -n $azure_arc_ns
k describe connectedclusters.arc.azure.com clustermetadata -n $azure_arc_ns

# verify
az connectedk8s list -g $k3s_rg_name -o table # -c $azure_arc_k3s --cluster-type connectedClusters 
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

az k8sconfiguration create --name $arc_config_name_k3s --cluster-name $azure_arc_k3s -g $k3s_rg_name --cluster-type connectedClusters \
  --repository-url $gitops_url \
  --enable-helm-operator true \
  --operator-namespace $arc_gitops_namespace \
  --operator-instance-name $arc_operator_instance_name_k3s \
  --operator-type flux \
  --operator-params='--git-poll-interval=1m' \
  --scope cluster # namespace

az k8sconfiguration list --cluster-name $azure_arc_k3s -g $k3s_rg_name --cluster-type connectedClusters
az k8sconfiguration show --cluster-name $azure_arc_k3s --name $arc_config_name_k3s -g $k3s_rg_name --cluster-type connectedClusters

# notices the new Pending configuration
complianceState=$(az k8sconfiguration show --cluster-name $azure_arc_k3s --name $arc_config_name_k3s -g $k3s_rg_name --cluster-type connectedClusters --query 'complianceStatus.complianceState')
echo "Compliance State " : $complianceState

k get gitconfigs.clusterconfig.azure.com -n $arc_gitops_namespace
k describe gitconfigs.clusterconfig.azure.com -n $arc_gitops_namespace

# https://kubernetes.io/docs/concepts/extend-kubernetes/operator
# https://github.com/fluxcd/helm-operator/blob/master/chart/helm-operator/CHANGELOG.md#060-2020-01-26
k get po -L app=helm-operator -n $arc_gitops_namespace
k describe po k3s-cluster-config-helm-gitops-helm-operator-c546b564b-glcf5 -n $arc_gitops_namespace | grep -i "image" # ==> Image: docker.io/fluxcd/helm-operator:1.0.0-rc4
# https://hub.docker.com/r/fluxcd/helm-operator/tags
```

### Config Private repo 
If you are using a private git repo, then you need to perform one more task to close the loop: you need to add the public key that was generated by flux as a Deploy key in the repo.
```sh
az k8sconfiguration show --cluster-name $azure_arc_k3s --name $arc_config_name_k3s -g $k3s_rg_name --query 'repositoryPublicKey'
```

### Validate the Kubernetes configuration
```sh
k get ns --show-labels
k -n team-a get cm -o yaml
k -n itops get all
k get ep -n gitops
k get events
k logs -l app.kubernetes.io/component=flux-logs-agent -c flux-logs-agent -n $azure_arc_ns 
# az k8sconfiguration delete --name '<config name>' -g '<resource group name>' --cluster-name '<cluster name>' --cluster-type connectedClusters
helm ls
```

## Deploy applications using Helm and GitOps

You can learn more about the HelmRelease in the official [Helm Operator documentation](https://docs.fluxcd.io/projects/helm-operator/en/stable/references/helmrelease-custom-resource)

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-with-helm](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/use-gitops-with-helm)

```sh

az k8sconfiguration create --name "$arc_config_name_k3s-azure-voting-app" --cluster-name $azure_arc_k3s -g $k3s_rg_name \
  --operator-instance-name "$arc_operator_instance_name_k3s-azure-voting-app" \
  --operator-namespace prod \
  --enable-helm-operator \
  --helm-operator-version='0.6.0' \
  --helm-operator-params='--set helm.versions=v3' \
  --repository-url $gitops_helm_url \
  --operator-params='--git-readonly --git-path=releases/prod' \
  --scope namespace \
  --cluster-type connectedClusters

az k8sconfiguration show --resource-group $k3s_rg_name --name "$arc_config_name_k3s-azure-voting-app" --cluster-name $azure_arc_k3s --cluster-type connectedClusters

# notices the new Pending configuration
complianceState=$(az k8sconfiguration show --cluster-name $azure_arc_k3s --name "$arc_config_name_k3s-azure-voting-app" -g $k3s_rg_name --cluster-type connectedClusters --query 'complianceStatus.complianceState')
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

az policy definition create --name 
                            [--description]
                            [--display-name]
                            [--management-group]
                            [--metadata]
                            [--mode]
                            [--params]
                            [--rules]
                            [--subscription]


# Create a remediation for a specific assignment
Start-AzPolicyRemediation -Name 'myRemedation' -PolicyAssignmentId '/subscriptions/${subId}/providers/Microsoft.Authorization/policyAssignments/{myAssignmentId}'

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

The same analytics workspace is shared for all k8s clusters, do not recreate it if it was lareday created in previous use case.

```sh
az monitor log-analytics workspace list
az monitor log-analytics workspace create -n $analytics_workspace_name --location $location -g $common_rg_name --verbose
az monitor log-analytics workspace list
az monitor log-analytics workspace show -n $analytics_workspace_name -g $common_rg_name --verbose

export analytics_workspace_id=$(az monitor log-analytics workspace show -n $analytics_workspace_name -g $common_rg_name --query id)
echo "analytics_workspace_id:" $analytics_workspace_id

curl -o enable-monitoring.sh -L https://aka.ms/enable-monitoring-bash-script
export azureArc_K3S_ClusterResourceId=$(az connectedk8s show -g $k3s_rg_name --name $azure_arc_k3s --query id)

k config view --minify
k config get-contexts
k config rename-context default k3s-default
export kubeContext="k3s-default" #"<kubeContext name of your k8s cluster>"

bash enable-monitoring.sh --resource-id $azureArc_K3S_ClusterResourceId --workspace-id $analytics_workspace_id --kube-context $kubeContext

```
Verify :

- After you've enabled monitoring, it might take about 15 minutes before you can view health metrics for the cluster.
- By default, the containerized agent collects the stdout/ stderr container logs of all the containers running in all the namespaces except kube-system. To configure container log collection specific to particular namespace or namespaces, review [Container Insights agent configuration](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-agent-config) to configure desired data collection settings to your ConfigMap configurations file.
- To learn how to stop monitoring your Arc enabled Kubernetes cluster with Azure Monitor for containers, see [How to stop monitoring your hybrid cluster](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-optout-hybrid#how-to-stop-monitoring-on-arc-enabled-kubernetes).

### Clean-Up
```sh
curl -o disable-monitoring.sh -L https://aka.ms/disable-monitoring-bash-script
bash disable-monitoring.sh --resource-id $azureArcClusterResourceId # --kube-context $kubeContext
```

## Manage Kubernetes policy within a connected cluster with Azure Policy for Kubernetes

See [https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes?toc=/azure/azure-arc/kubernetes/toc.json](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes?toc=/azure/azure-arc/kubernetes/toc.json)

```sh

```

## IoT Edge workloads integration

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/deploy-azure-iot-edge-workloads](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/deploy-azure-iot-edge-workloads)

```sh

```

## Troubleshooting

See [Azure Arc doc](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/troubleshooting)