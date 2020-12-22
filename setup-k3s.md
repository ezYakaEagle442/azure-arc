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

az network nsg rule create --access Allow --destination-port-range 32380 --source-address-prefixes Internet --name "Allow 32380 from Internet" --nsg-name $k3s_nsg -g $k3s_rg_name --priority 140

az network nsg rule create --access Allow --destination-port-range 32333 --source-address-prefixes Internet --name "Allow 32333 from Internet" --nsg-name $k3s_nsg -g $k3s_rg_name --priority 150

az network vnet subnet update --name $k3s_subnet_name --network-security-group $k3s_nsg --vnet-name $k3s_vnet_name -g $k3s_rg_name


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
--name k3sHealthProbe-80 \
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
--probe-name k3sHealthProbe-80

az network lb probe create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3sHealthProbe-443 \
--protocol tcp \
--port 443

az network lb rule create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3sHTTPS \
--protocol tcp \
--frontend-port 443 \
--backend-port 443 \
--frontend-ip-name k3sFrontEnd \
--backend-pool-name k3sBackEndPool \
--probe-name k3sHealthProbe-443

az network lb probe create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3sHealthProbe-6443 \
--protocol tcp \
--port 6443

az network lb rule create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3sAPI \
--protocol tcp \
--frontend-port 6443 \
--backend-port 6443 \
--frontend-ip-name k3sFrontEnd \
--backend-pool-name k3sBackEndPool \
--probe-name k3sHealthProbe-6443

az network lb probe create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3sHealthProbe-32380 \
--protocol tcp \
--port 32380

az network lb rule create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3s-32380 \
--protocol tcp \
--frontend-port 32380 \
--backend-port 32380 \
--frontend-ip-name k3sFrontEnd \
--backend-pool-name k3sBackEndPool \
--probe-name k3sHealthProbe-32380

az network lb probe create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3sHealthProbe-32333 \
--protocol tcp \
--port 32333

az network lb rule create \
--resource-group $k3s_rg_name \
--lb-name $k3s_lb \
--name k3s-32333 \
--protocol tcp \
--frontend-port 32333 \
--backend-port 32333 \
--frontend-ip-name k3sFrontEnd \
--backend-pool-name k3sBackEndPool \
--probe-name k3sHealthProbe-32333

```

## Create Azure VM

```sh

az network public-ip create --resource-group $k3s_rg_name --name $k3s_vm_pub_ip --sku "Standard"

k3s_vm_pub_ip_id=$(az network public-ip show -n $k3s_vm_pub_ip -g $k3s_rg_name --query "id" -o tsv)
echo "k3s_vm_pub_ip_id " $k3s_vm_pub_ip_id

k3s_vm_pub_ip_address=$(az network public-ip show -n $k3s_vm_pub_ip -g $k3s_rg_name --query "ipAddress" -o tsv)
echo "k3s_vm_pub_ip_address" $k3s_vm_pub_ip_address

az network nic create --name $k3s_vm_name-nic --vnet-name $k3s_vnet_name --subnet $k3s_subnet_name --network-security-group $k3s_nsg --public-ip-address $k3s_vm_pub_ip --lb-name $k3s_lb --lb-address-pools k3sBackEndPool -g $k3s_rg_name

# When specifying an existing NIC, do not specify NSG, public IP, ASGs, VNet or subnet
az vm create --name $k3s_vm_name \
    --image UbuntuLTS \
    --admin-username $k3s_admin_username \
    --nics $k3s_vm_name-nic \
    --resource-group $k3s_rg_name \
    --size Standard_B2s \
    --location $location \
    --ssh-key-values ~/.ssh/$ssh_key.pub
    # --vnet-name $k3s_vnet_name \
    # --subnet $k3s_subnet_name \
    # --nsg $k3s_nsg \

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
sudo apt install jq

```
[Install AZ CLI in VM](tools.md)
[Install Azure Arc CLI extension](setup-prereq.md#install-azure-arc-cli-extension)
[Install HELM in VM](tools.md#how-to-install-helm-on-ubuntu-or-wsl)
[Configure HELM in VM](setup-helm.md)

## Create K3S

```sh

# Installing k3s to /usr/local/bin/k3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik --kube-apiserver-arg default-not-ready-toleration-seconds=10 --kube-apiserver-arg default-unreachable-toleration-seconds=10 --kube-controller-arg node-monitor-period=10s --kube-controller-arg node-monitor-grace-period=10s --kubelet-arg node-status-update-frequency=5s" sh - # --bind-address $k3s_vm_pub_ip_address --advertise-address $k3s_vm_pub_ip_address
# wget -q -O - https://raw.githubusercontent.com/rancher/k3s/master/install.sh | sh -
service k3s status
k3s --version

# check logs
journalctl -u k3s
cat /var/log/syslog | grep k3s

sudo ls -al /usr/local/bin/k3s

# A kubeconfig file is written to /etc/rancher/k3s/k3s.yaml
# https://github.com/rancher/k3s/issues/1126
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
ls -al /etc/rancher/k3s/k3s.yaml
sudo chmod 744 /etc/rancher/k3s/k3s.yaml

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

# Since 1.19  K3S provides client certificate auth no more usr/pwd, see https://github.com/k3s-io/k3s/issues/1616
# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.19.md#no-really-you-must-read-this-before-you-upgrade

# https://github.com/k3s-io/k3s/issues/2342#issuecomment-703830567
# Support for Basic authentication has been removed from upstream Kubernetes. 
# Note that this is not just deprecated or disabled, but deleted from the codebase in 1.19: kubernetes/kubernetes#89069
k3s_usr=$(k config view -o json | jq -Mr '.users[0].user.username')
k3s_pwd=$(k config view -o json | jq -Mr '.users[0].user.password')
echo "K3S User " $k3s_usr
echo "K3S PWD " $k3s_pwd


# Get all certificates
# https://gist.github.com/xueshanf/71f188c58553c82bda16f80483e71918

k config view --raw
k config view --minify --raw --output 'jsonpath={..cluster.certificate-authority-data}' | base64 -d > k3s-server-ca.crt # | openssl x509 -text -out -)
cat k3s-server-ca.crt

k config view --minify --raw --output 'jsonpath={..user.client-certificate-data}' | base64 -d > k3s-admin-user.crt # | openssl x509 -text -out -)
cat k3s-admin-user.crt

k config view --minify --raw --output 'jsonpath={..user.client-key-data}' | base64 -d > k3s-admin-user-key.key
cat k3s-admin-user-key.key

# Check the certificates with SSLShopper : https://www.sslshopper.com/certificate-decoder.html
# `cat k3s-server-ca.crt > k3s-admin-user.crt`

# https://medium.com/better-programming/k8s-tips-give-access-to-your-clusterwith-a-client-certificate-dfb3b71a76fe
# https://kubernetes.io/docs/reference/access-authn-authz/authentication/#x509-client-certs
k config set-credentials k3s-admin \
  --client-key=k3s-admin-user-key.key \
  --client-certificate=k3s-admin-user.crt \
  --embed-certs=false

# curl -k https://localhost:6443/api/v1/namespaces -H "Authorization: Bearer $token_secret_value" -H 'Accept: application/json'
curl -k https://localhost:6443/api/v1/namespaces -H 'Accept: application/json' --cert k3s-admin-user.crt --key k3s-admin-user-key.key  #--user $k3s_usr:$k3s_pwd 

sudo cat /etc/rancher/k3s/k3s.yaml
echo "Now please Update the server: with the external URL of the Load Balancer "
echo "replacing server: https://127.0.0.1:6443 "
echo "with server: https://k3s."${k3s_lb_pub_ip_address}".xip.io:6443 "

# sudo sed -i "s/127.0.0.1/${k3s_lb_pub_ip_address}/g" /etc/rancher/k3s/k3s.yaml 
# sudo vim /etc/rancher/k3s/k3s.yaml

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo cp /etc/rancher/k3s/k3s.yaml /home/$k3s_admin_username/.kube/config

sudo chown $k3s_admin_username:$k3s_admin_username /home/$k3s_admin_username/.kube/config
sudo chown $k3s_admin_username:$k3s_admin_username /home/$k3s_admin_username/.kube
ls -al /home/$k3s_admin_username/.kube
cat /home/$k3s_admin_username/.kube/config
chmod 744 /home/$k3s_admin_username/.kube/config

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

curl -sfL https://get.k3s.io | K3S_URL=https://${k3s_lb_pub_ip_address} K3S_TOKEN= $NODE_TOKEN sh -


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
git clone https://github.com/ezYakaEagle442/azure-arc

k apply -f ./app/hello-kubernetes.yaml
k get deploy
k get po

hello_svc_cluster_ip=$(k get svc hello-kubernetes -o=custom-columns=":spec.clusterIP")
curl http://$hello_svc_cluster_ip:32380

hello_svc_lb_ip=$(k get svc/hello-kubernetes -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
curl http://$hello_svc_lb_ip:32380
echo "Test from your browser : http://$k3s_lb_pub_ip_address:32380/hello-kubernetes"


```

## Register to Azure Arc.

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster)
```sh

azure_arc_ns="azure-arc"

# Deploy Azure Arc Agents for Kubernetes using Helm 3, into the azure-arc namespace
az connectedk8s connect --name $azure_arc_k3s -l $location -g $k3s_rg_name
k get crds
k get azureclusteridentityrequests.clusterconfig.azure.com -n $azure_arc_ns
k describe azureclusteridentityrequests.clusterconfig.azure.com config-agent-identity-request -n $azure_arc_ns

k get connectedclusters.arc.azure.com -n $azure_arc_ns
k describe connectedclusters.arc.azure.com clustermetadata -n $azure_arc_ns

# verify
az connectedk8s list --subscription $subId -o table
az connectedk8s list -g $k3s_rg_name -o table # -c $azure_arc_k3s --cluster-type connectedClusters

# -o tsv is MANDATORY to remove quotes
azure_arc_k3s_id=$(az connectedk8s show --name $azure_arc_k3s -g $k3s_rg_name -o tsv --query id)

helm status azure-arc --namespace default 

# Azure Arc enabled Kubernetes deploys a few operators into the azure-arc namespace. You can view these deployments and pods here:
k get deploy,po -n $azure_arc_ns 
k get po -o=custom-columns=':.metadata.name' -n $azure_arc_ns
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
az k8sconfiguration create --name $arc_config_name_k3s --cluster-name $azure_arc_k3s -g $k3s_rg_name --cluster-type connectedClusters \
  --repository-url $gitops_url \
  --enable-helm-operator true \
  --operator-namespace $arc_gitops_namespace \
  --operator-instance-name $arc_operator_instance_name_k3s \
  --operator-type flux \
  --operator-params='--git-poll-interval=1m --sync-garbage-collection' \
  --scope cluster # namespace

az k8sconfiguration list --cluster-name $azure_arc_k3s -g $k3s_rg_name --cluster-type connectedClusters
az k8sconfiguration show --cluster-name $azure_arc_k3s --name $arc_config_name_k3s -g $k3s_rg_name --cluster-type connectedClusters

repositoryPublicKey=$(az k8sconfiguration show --cluster-name $azure_arc_k3s --name $arc_config_name_k3s -g $k3s_rg_name --cluster-type connectedClusters --query 'repositoryPublicKey')
echo "repositoryPublicKey : " $repositoryPublicKey
echo "Add this Public Key to your GitHub Project Deploy Key and allow write access at https://github.com/$github_usr/arc-k8s-demo/settings/keys"

# notices the new Pending configuration
complianceState=$(az k8sconfiguration show --cluster-name $azure_arc_k3s --name $arc_config_name_k3s -g $k3s_rg_name --cluster-type connectedClusters --query 'complianceStatus.complianceState')
echo "Compliance State " : $complianceState

git_config=$(k get gitconfigs.clusterconfig.azure.com -n $arc_gitops_namespace -o jsonpath={.items[0].metadata.name})
k describe gitconfigs.clusterconfig.azure.com $git_config -n $arc_gitops_namespace

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
flux_logs_agent_pod=$(k get po -l app.kubernetes.io/component=flux-logs-agent -n $azure_arc_ns -o jsonpath={.items[0].metadata.name})
k logs $flux_logs_agent_pod -c flux-logs-agent -n $azure_arc_ns 
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
echo "Open your brower to test the App at http://$azure_vote_front_url"

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

az policy definition create --name "k3s-gitops-enforcement"
                            --description "Ensure to deploy GitOps to Kubernetes cluster"
                            --display-name "k3s-gitops-enforcement"
                            [--management-group]
                            [--metadata]
                            [--mode]
                            --params --git-poll-interval=1m
                            [--rules]
                            [--subscription]

az policy assignment list -g $k3s_rg_name
gitOpsAssignmentId=$(az policy assignment show --name "k3s-gitops-enforcement -g $k3s_rg_name --query id)


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
az monitor log-analytics workspace create -n $analytics_workspace_name --location $location -g $common_rg_name --verbose
az monitor log-analytics workspace list
az monitor log-analytics workspace show -n $analytics_workspace_name -g $common_rg_name --verbose

export analytics_workspace_id=$(az monitor log-analytics workspace show -n $analytics_workspace_name -g $common_rg_name --query id)
echo "analytics_workspace_id:" $analytics_workspace_id

curl -o enable-monitoring.sh -L https://aka.ms/enable-monitoring-bash-script

# https://github.com/Azure/azure-cli/issues/8401 --query id ==> -o tsv is NECESSARY
export azureArc_K3S_ClusterResourceId=$(az connectedk8s show -g $k3s_rg_name --name $azure_arc_k3s --query id -o tsv)

k config view --minify
k config get-contexts
k config rename-context default k3s-default
export kubeContext="k3s-default" #"<kubeContext name of your k8s cluster>"

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm ls --kube-context k3s-default -v=10
# if the above test fails the enable-monitoring.sh script will fails as well ...
bash enable-monitoring.sh --resource-id $azureArc_K3S_ClusterResourceId --workspace-id $analytics_workspace_id --kube-context $kubeContext

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
az_policy_sp_password=$(az ad sp create-for-rbac --name $appName-k3s --role "Policy Insights Data Writer (Preview)" --scopes $azure_arc_k3s_id --query password --output tsv)

echo $az_policy_sp_password > az_policy_sp_password.txt
echo "Azure Policy Service Principal Password saved to ./az_policy_sp_password.txt IMPORTANT Keep your password ..." 
# az_policy_sp_password=`cat az_policy_sp_password.txt`
az_policy_sp_id=$(az ad sp show --id http://$appName-k3s --query appId -o tsv)
#az_policy_sp_id=$(az ad sp list --all --query "[?appDisplayName=='${appName-k3s}'].{appId:appId}" --output tsv)
#az_policy_sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName-k3s}'].{appId:appId}" --output tsv)
echo "Azure Policy Service Principal ID:" $az_policy_sp_id 
echo $az_policy_sp_id > az_policy_sp_id.txt
# az_policy_sp_id=`cat az_policy_sp_id.txt`
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
    --set azurepolicy.env.resourceid=$azureArc_K3S_ClusterResourceId \
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

Wait for 20  minutes (Azure Policy refreshes on a 15 minute cycle) and check the logs :

```sh
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

container_no_privilege_constraint=$(k get k8sazurecontainernoprivilege.constraints.gatekeeper.sh -n gatekeeper-system -o jsonpath="{.items[*].metadata.name}")
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

## IoT Edge workloads integration

See [https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/deploy-azure-iot-edge-workloads](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/deploy-azure-iot-edge-workloads)

```sh

```

## Troubleshooting

See [Azure Arc doc](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/troubleshooting)

# Clean-Up
```sh
helm uninstall azure-policy-addon

curl -o disable-monitoring.sh -L https://aka.ms/disable-monitoring-bash-script
bash disable-monitoring.sh --resource-id $azureArc_K3S_ClusterResourceId --kube-context $kubeContext
# az monitor log-analytics workspace delete --workspace-name $analytics_workspace_name -g $common_rg_name

az k8sconfiguration delete --name "$arc_config_name_k3s-azure-voting-app" --cluster-name $azure_arc_k3s --cluster-type connectedClusters -g $k3s_rg_name -y
az k8sconfiguration delete --name $arc_config_name_k3s --cluster-name $azure_arc_k3s --cluster-type connectedClusters -g $k3s_rg_name -y

az policy definition delete --name "k3s-gitops-enforcement"
az policy assignment delete --name xxx -g $k3s_rg_name

az connectedk8s delete --name $azure_arc_k3s -g $k3s_rg_name -y

# unsinstall k3S : https://rancher.com/docs/k3s/latest/en/installation/uninstall/
/usr/local/bin/k3s-uninstall.sh
# /usr/local/bin/k3s-agent-uninstall.sh


az vm delete --name $k3s_vm_name -g $k3s_rg_name -y
az network nic delete --name nic-k3s -g $k3s_rg_name

az network lb delete --name $k3s_lb 
az network public-ip delete --name $k3s_lb_pub_ip -g $k3s_rg_name

az network vnet subnet update --name $k3s_subnet_name --vnet-name $k3s_vnet_name --network-security-group "" -g $k3s_rg_name
```

# K3S Fun with Rasberry Pi

See:
- [Setup K3S on a Raspberry-Pi in 15 minutes](https://medium.com/@alexellisuk/walk-through-install-kubernetes-to-your-raspberry-pi-in-15-minutes-84a8492dc95a)
- [https://github.com/Sheldonwl/rpi-travel-case](https://github.com/Sheldonwl/rpi-travel-case)
- [https://doingdata.cloud/2020/05/24/how-to-k3s-on-raspberry-pi](https://doingdata.cloud/2020/05/24/how-to-k3s-on-raspberry-pi)
- [https://opensource.com/article/20/3/kubernetes-raspberry-pi-k3s](https://opensource.com/article/20/3/kubernetes-raspberry-pi-k3s)
- [https://blog.alexellis.io/raspberry-pi-homelab-with-k3sup](https://blog.alexellis.io/raspberry-pi-homelab-with-k3sup)
- []()