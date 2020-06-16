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

# sudo ./k3s server --no-flannel --disable-agent  --token k3stoktoktok & 
# sudo ./k3s server --cluster-cidr “10.42.0.0/24” --service-cidr “10.43.0.0/24” --cluster-dns “10.43.0.10” --token k3stoktoktok &

sudo ls -al /var/lib/rancher/k3s/server
# sudo ./k3s agent --server https://$myIP:6443 --no-flannel --node-ip $myIP --token k3stoktoktok

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

```sh

# Deploy Azure Arc Agents for Kubernetes using Helm 3, into the azure-arc namespace
az connectedk8s connect --name $azure_arc_k3s  -l $location -g $k3s_rg_name

# verify
az connectedk8s list -g $k3s_rg_name -o table # -c $azure_arc_k3s --cluster-type connectedClusters 

# Azure Arc enabled Kubernetes deploys a few operators into the azure-arc namespace. You can view these deployments and pods here:
k -n azure-arc get deploy,po

```

## Enable GitOps on a connected cluster

```sh

```

## Deploy applications using Helm and GitOps

```sh

```


## Enable GitOps on an Azure Kubernetes Service (AKS) cluster

```sh

```


## Use Azure Policy to enable GitOps on clusters at scale

```sh

```


## Monitor a connected cluster with Azure Monitor for containers

See [https://aka.ms/arc-k8s-ci-onboarding](https://aka.ms/arc-k8s-ci-onboarding)
```sh

```

## Manage Kubernetes policy within a connected cluster with Azure Policy for Kubernetes

See [https://github.com/Azure/azure-arc-kubernetes-preview/blob/master/docs/use-azure-policy.md](https://github.com/Azure/azure-arc-kubernetes-preview/blob/master/docs/use-azure-policy.md)

```sh

```