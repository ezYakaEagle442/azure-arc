# Set-up environment variables

<span style="color:red">/!\ IMPORTANT </span> : your **appName** & **cluster_name** values MUST BE UNIQUE

## Core variables
```sh

az provider register --namespace Microsoft.Kubernetes
az provider show -n Microsoft.Kubernetes --query  "resourceTypes[?resourceType == 'connectedClusters']".locations 

# az account list-locations : francecentral | northeurope | westeurope | eastus2
location=westeurope 
echo "location is : " $location 

appName="azarc" 
echo "appName is : " $appName 

ssh_passphrase="<your secret>"
ssh_key="${appName}-key" # id_rsa

# Storage account name must be between 3 and 24 characters in length and use numbers and lower-case letters only
storage_name="stwe""${appName,,}"
echo "Storage name:" $storage_name

target_namespace="staging"
echo "Target namespace:" $target_namespace

dns_zone="cloudapp.azure.com"
echo "DNS Zone is : " $dns_zone

app_dns_zone="kissmyapp.${location}.${dns_zone}"
echo "App DNS zone " $app_dns_zone

custom_dns="akshandsonlabs.com"
echo "Custom DNS is : " $custom_dns

git_url="https://github.com/your-project/xxx.git"
echo "Project git repo URL : " $git_url 

git_url_springboot="https://github.com/spring-projects/spring-petclinic.git"
echo "Project git repo URL : " $git_url_springboot 

```

## Azure Arc
```sh
azure_arc_k3s="Azure-Arc-K3S"
echo "Azure Arc K3S registered Cluster:" $azure_arc_k3s 

azure_arc_aks="Azure-Arc-AKS"
echo "Azure Arc AKS registered Cluster:" $azure_arc_aks 

azure_arc_aro="Azure-Arc-ARO"
echo "Azure Arc ARO registered Cluster:" $azure_arc_aro 

azure_arc_gke="Azure-Arc-GKE"
echo "Azure Arc GKE registered Cluster:" $azure_arc_gke 

azure_arc_aws="Azure-Arc-AWS"
echo "Azure Arc K8S registered Cluster:" $azure_arc_aws 

azure_arc_minikube="Azure-Arc-MiniKube"
echo "Azure Arc Minikube registered Cluster:" $azure_arc_minikube 

azure_arc_kind="Azure-Arc-KIND"
echo "Azure Arc KIND registered Cluster:" $azure_arc_kind 

```

## K3S

```sh
k3s_rg_name="rg-${appName}-k3s-${location}" 
echo "K3S RG name:" $k3s_rg_name 

k3s_vm_name="vm-${appName}-k3s"
echo "K3S VM Name :" $k3s_vnet_name

k3s_vnet_name="vnet-${appName}-k3s"
echo "K3S VNet Name :" $k3s_vnet_name

k3s_subnet_name="snet-${appName}-k3s"
echo "K3S Subnet Name :" $k3s_subnet_name

k3s_admin_username="${appName}-admin"
echo "K3S admin user-name :" $k3s_admin_username

k3s_lb_pub_ip="pip-${appName}-k3s-lb-pub-IP"
echo "K3S LB Public IP :" $k3s_lb_pub_ip

k3s_lb="lbe-k3s-${appName}"
echo "K3S LB name :" $k3s_lb

```


## AKS

```sh

aks_rg_name="rg-${appName}-aks-${location}" 
echo "AKS RG name:" $aks_rg_name 

# target : version 1.17.4
aks_version=$(az aks get-versions -l $location --query 'orchestrators[-4].orchestratorVersion' -o tsv) 
echo "AKS version is :" $aks_version 

aks_cluster_name="aks-${appName}-${target_namespace}-101" #aks-<App Name>-<Environment>-<###>
echo "AKS Cluster name:" $aks_cluster_name

aks_network_plugin="azure"
echo "AKS Network Plugin is : " $aks_network_plugin 

aks_network_policy="azure"
echo "AKS Network Policy is : " $aks_network_policy 

aks_node_pool_name="${appName}aksnp"
echo "AKS Node Pool name:" $aks_node_pool_name

aks_vnet_name="vnet-aks-${appName}"
echo "AKS VNet Name :" $aks_vnet_name

aks_subnet_name="snet-aks-${appName}"
echo "AKS Subnet Name :" $aks_subnet_name

aks_admin_username="${appName}-admin"
echo "AKS admin user-name :" $aks_admin_username

acr_registry_name="acr${appName,,}"
echo "ACR registry Name :" $acr_registry_name

```




## ARO

```sh

aro_rg_name="rg-${appName}-aro-${location}" 
echo "ARO RG name:" $aro_rg_name 

aro_cluster_name="aro-${appName}-101" #aro-<App Name>-<Environment>-<###>
echo "ARO Cluster name:" $aro_cluster_name

aro_vnet_name="vnet-aro-${appName}"
echo "ARO VNet Name :" $aro_vnet_name

aro_master_subnet_name="snet-aro-master-${appName}"
echo "ARO Master Subnet Name :" $aro_master_subnet_name

aro_worker_subnet_name="snet-aro-worker-${appName}"
echo "ARO Workers Subnet Name :" $aro_worker_subnet_name

aro_pod_cidr=10.51.0.0/18 # must be /18 or larger https://docs.openshift.com/aro/4/networking/understanding-networking.html
echo "ARO Pod CIDR is : " $aro_pod_cidr 

aro_svc_cidr=10.52.0.0/18 # must be /18 or larger
echo "ARO Service CIDR is : " $aro_svc_cidr 

# Private or Public : https://github.com/Azure/azure-cli/blob/dev/src/azure-cli/azure/cli/command_modules/aro/_validators.py#L180
aro_apiserver_visibility="Public"
echo "ARO apiserver visibility is : " $aro_apiserver_visibility 

aro_ingress_visibility="Public"
echo "ARO ingress visibility is : " $aro_ingress_visibility 

aro_admin_username="${appName}-admin"
echo "ARO admin user-name :" $aro_admin_username

```


## Extra variables
Note: The here under variables are built based on the varibales defined above, you should not need to modify them, just run this snippet

```sh


```