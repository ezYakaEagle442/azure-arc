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

az network vnet subnet update --name ManagementSubnet --network-security-group $k3s_nsg --vnet-name $k3s_vnet_name -g $k3s_rg_name

```

## Create Azure VM

```sh
az vm create --name $k3s_vm_name \
    --image UbuntuLTS \
    --admin-username $k3s_admin_username \
    --resource-group $k3s_rg_name \
    --vnet-name $k3s_vnet_name \
    --subnet ManagementSubnet \
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


```

## Create K3S

```sh

# Installing k3s to /usr/local/bin/k3s
curl -sfL https://get.k3s.io | sh -
# wget -q -O - https://raw.githubusercontent.com/rancher/k3s/master/install.sh | sh -
sudo service k3s status
k3s --version

sudo ls -al /usr/local/bin/k3s

# A kubeconfig file is written to /etc/rancher/k3s/k3s.yaml

sudo ./k3s help

sudo cat /var/lib/rancher/k3s/server/node-token
# sudo ./k3s server --no-flannel --disable-agent  --token k3stoktoktok & 
# sudo ./k3s server --cluster-cidr “10.42.0.0/24” --service-cidr “10.43.0.0/24” --cluster-dns “10.43.0.10” --token k3stoktoktok &

sudo ls -al /var/lib/rancher/k3s/server
# sudo ./k3s agent --server https://$myIP:6443 --no-flannel --node-ip $myIP --token k3stoktoktok

sudo k3s kubectl version
sudo k3s kubectl get nodes
sudo k3s kubectl get pods -A
sudo cat /var/lib/rancher/k3s/server/node-token

source <(k3s kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(k3s kubectl completion bash)" >> ~/.bashrc 
alias k=sudo k3s kubectl
complete -F __start_kubectl k

# Check at https://localhost:6443 | https://$k3s_network_interface_pub_ip:6443



```