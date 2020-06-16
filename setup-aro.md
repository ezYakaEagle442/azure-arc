See:
- [Azure ARO docs](https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster)
- [ARO 4.x docs](https://docs.openshift.com/aro/4/registry/architecture-component-imageregistry.html)
- [http://aroworkshop.io](http://aroworkshop.io)
- [https://aka.ms/aroworkshop-devops](https://aka.ms/aroworkshop-devops)


# Setup ARO

```sh

pull_secret=`cat pull-secret.txt`

az provider show -n  Microsoft.RedHatOpenShift --query  "resourceTypes[?resourceType == 'OpenShiftClusters']".locations 
curl -sSL aka.ms/where/aro | bash

az aro create \
  --name $aro_aro_cluster_name \
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
  --resource-group $aro_aro_rg_name 

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

aro_managed_rg_name=`echo -e $managed_rg | cut -d  "/" -f5`
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

# https://docs.microsoft.com/en-us/azure/aks/availability-zones#verify-node-distribution-across-zones
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

```sh

oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
aro_reg_default_route=$(oc get route default-route -n openshift-image-registry -o json | jq -Mr '.status.ingress[0].host')
echo "ARO Registry default route : " $aro_reg_default_route

oc policy add-role-to-user registry-viewer <user_name> # To pull images
oc policy add-role-to-user registry-editor <user_name> # To Push images
oc login $aro_api_server_url -u $aro_usr -p $aro_pwd
docker login -u $aro_usr -p $(oc whoami -t) https://image-registry.openshift-image-registry.svc:5000
docker login -u pinpin@ms.grd -p $token_secret_value $aro_reg_default_route

# https://docs.openshift.com/aro/4/registry/accessing-the-registry.html#registry-accessing-metrics_accessing-the-registry
curl --insecure -s -u $aro_usr -p $(oc whoami -t) https://image-registry.openshift-image-registry.svc:5000/extensions/v2/metrics | grep imageregistry | head -n 20
curl --insecure -s -u pinpin@ms.grd -p $token_secret_value https://$aro_reg_default_route/extensions/v2/metrics | grep imageregistry | head -n 20
```