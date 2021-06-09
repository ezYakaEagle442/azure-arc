See :
- [https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_postgresql_hyperscale_arm_template](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_postgresql_hyperscale_arm_template/)
- [https://docs.microsoft.com/en-us/azure/azure-arc/data/overview](https://docs.microsoft.com/en-us/azure/azure-arc/data/overview)

# Azure Pre-req

Install [client tools](https://docs.microsoft.com/en-us/azure/azure-arc/data/install-client-tools)


Create Service Principal
```sh
arc_data_sp_password=$(az ad sp create-for-rbac --name $appName-data --role contributor --query password -o tsv)
echo $arc_data_sp_password > arc_data_sp_password.txt
echo "Service Principal Password saved to ./arc_data_sp_password.txt IMPORTANT Keep your password ..." 
# arc_data_sp_password=`cat arc_data_sp_password.txt`
arc_data_sp_id=$(az ad sp show --id http://$appName-data --query appId -o tsv)
#arc_data_sp_id=$(az ad sp list --all --query "[?appDisplayName=='${appName}-data'].{appId:appId}" --output tsv)
#arc_data_sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}-data'].{appId:appId}" -o tsv)
echo "Arc for data Service Principal ID:" $arc_data_sp_id 
echo $arc_data_sp_id > arc_data_sp_id.txt
# arc_data_sp_id=`cat arc_data_sp_id.txt`
az ad sp show --id $arc_data_sp_id
```

```sh
az provider register --namespace Microsoft.AzureArcData
az provider show -n Microsoft.AzureArcData -o table
```

# Deploy Azure Arc Data Controller (Vanilla) on AKS using an ARM Template 

See [https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_dc_vanilla_arm_template](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_dc_vanilla_arm_template)

**Note: Currently, On Azure Kubernetes Service (AKS), Kubernetes version 1.19.x is not supported.**

```sh
cd /azure_arc/azure_arc_data_jumpstart/aks/arm_template/postgres_hs
az aks get-versions -o table -l $location

arc_data_aks_rg_name="rg-${appName}-data-aks-pgsql-${location}" 

az group create --name $arc_data_aks_rg_name --location $location

az deployment group create \
--resource-group $arc_data_aks_rg_name \
--name ${appName}-data-aks-pgsql \
--template-uri https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_data_jumpstart/aks/arm_template/postgres_hs/azuredeploy.json \
--parameters /aks/arm_template/postgres_hs/azuredeploy.parameters.json


```

# Deploy Azure PostgreSQL Hyperscale on AKS using an ARM Template

By the end of this guide, you will have an AKS cluster deployed with an Azure Arc Data Controller, Azure PostgreSQL Hyperscale with a sample database and a Microsoft Windows Server 2019 (Datacenter) Azure VM, installed & pre-configured with all the required tools needed to work with Azure Arc Data Services.

See [https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_postgresql_hyperscale_arm_template](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_postgresql_hyperscale_arm_template)

**Note: Currently, On Azure Kubernetes Service (AKS), Kubernetes version 1.19.x is not supported.**

```sh
cd /azure_arc/azure_arc_data_jumpstart/aks/arm_template/postgres_hs
az aks get-versions -o table  -l $location

arc_data_aks_rg_name="rg-${appName}-data-aks-pgsql-${location}" 

az group create --name $arc_data_aks_rg_name --location $location

az deployment group create --name azarc-data-aks-pgsql \
--resource-group $arc_data_aks_rg_name \
--name ${appName}-data-aks-pgsql \
--template-uri https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_data_jumpstart/aks/arm_template/postgres_hs/azuredeploy.json \
--parameters azure_arc_data_jumpstart/aks/arm_template/postgres_hs/azuredeploy.parameters.json


azdata arc dc export --path C:\Tmp\arc_data_ctr_aks_pgsql_logs.json --type logs --force
azdata arc dc export --path C:\Tmp\arc_data_ctr_aks_pgsql_metrics.json --type metrics --force
azdata arc dc export --path C:\Tmp\arc_data_ctr_aks_pgsql_usage.json --type usage --force

azdata arc dc upload --path C:\Tmp\arc_data_ctr_aks_pgsql_logs.json
azdata arc dc upload --path C:\Tmp\arc_data_ctr_aks_pgsql_metrics.json
azdata arc dc upload --path C:\Tmp\arc_data_ctr_aks_pgsql_usage.json

```


# Deployment on GKE

## GCP Pre-req
```sh
gcloud version
sudo /home/$USER/google-cloud-sdk/bin/gcloud components update -Y

gcloud auth login $GKE_ACCOUNT

gcloud config list
gcloud config set account $GKE_ACCOUNT
GKE_DATA_PROJECT_ID="$GKE_DATA_PROJECT-$(uuidgen | cut -d '-' -f2 | tr '[A-Z]' '[a-z]')"
gcloud projects create $GKE_DATA_PROJECT_ID --name $GKE_DATA_PROJECT --verbosity=info
gcloud projects list 
gcloud config set project $GKE_DATA_PROJECT_ID

# You need to enable GKE API
echo "You need to enable GKE API, see at https://console.cloud.google.com/apis/api/container.googleapis.com/overview?project=$GKE_DATA_PROJECT_ID"
```

Next, set up a service account key, which Terraform will use to create and manage resources in your GCP project.
Copy the credentials JSON file to the azure_arc_servers_jumpstart/gcp/ubuntu/terraform directory.

[https://cloud.google.com/iam/docs/creating-managing-service-account-keys](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)

```sh
gcloud iam service-accounts create sa-azure-arc-data --display-name="Azure Arc for Data Service Account" --description="Azure Arc for Data Service Account" --project $GKE_DATA_PROJECT_ID

gcloud iam service-accounts list --project $GKE_DATA_PROJECT_ID
gcloud iam service-accounts describe sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com --project $GKE_DATA_PROJECT_ID | grep -i "uniqueId: "

gcloud iam service-accounts keys create ~/gke-arc-data-sa-key.json --iam-account sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com --project $GKE_DATA_PROJECT_ID
gcloud iam service-accounts keys list --iam-account sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com --project $GKE_DATA_PROJECT_ID

gcloud container clusters list --project $GKE_DATA_PROJECT_ID
gcloud config set project $GKE_DATA_PROJECT
gcloud config set project $GKE_DATA_PROJECT_ID
gcloud config list
gcloud container clusters list --project $GKE_DATA_PROJECT_ID


cd azure_arc_data_jumpstart/gke/postgres_hs/terraform
gcloud container get-server-config --zone $GKE_ZONE


# If you get this error :  googleapi: Error 403: Required 'compute.zones.get' permission for 'projects/
# https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/issues/459
# https://stackoverflow.com/questions/48232189/google-compute-engine-required-compute-zones-get-permission-error
# requires roles: roles/compute.instanceAdmin , roles/editor , roles/iam.serviceAccountUser

# IMPORTANT : SA must be owner
gcloud projects add-iam-policy-binding $GKE_DATA_PROJECT_ID \
    --member="serviceAccount:sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/owner"

gcloud projects add-iam-policy-binding $GKE_DATA_PROJECT_ID \
    --member="serviceAccount:sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.instanceAdmin"

gcloud projects add-iam-policy-binding $GKE_DATA_PROJECT_ID \
    --member="serviceAccount:sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"

gcloud projects add-iam-policy-binding $GKE_DATA_PROJECT_ID \
    --member="serviceAccount:sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
    
```

## Deploy an Azure PostgreSQL Hyperscale Deployment on GKE using a Terraform plan

see [https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/gke/gke_postgres_hs_terraform/#deploy-an-azure-postgresql-hyperscale-deployment-on-gke-using-a-terraform-plan](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/gke/gke_postgres_hs_terraform/#deploy-an-azure-postgresql-hyperscale-deployment-on-gke-using-a-terraform-plan)


Ensure to have the GCP project, SA et keys created ax described in the previous [pre-req section](#GCP-Pre-req)

Deploy IaC with TF
Edit scripts/vars.sh and update each of the variables with the appropriate values.
see azure_arc_data_jumpstart/gke/postgres_hs/terraform/example/TF_VAR_example.sh


```sh

cp ~/gke-arc-data-sa-key.json azure_arc_data_jumpstart/gke/postgres_hs/terraform

cat <<EOF >> scripts/vars.sh
export TF_VAR_gcp_project_id={gcp project id}
export TF_VAR_gcp_credentials_filename=gke-arc-data-sa-key.json
export TF_VAR_gcp_region=europe-west4
export TF_VAR_ARC_DC_REGION=westeurope
export TF_VAR_gcp_zone=${GKE_ZONE}
export TF_VAR_gke_cluster_name=arc-data-gke
export TF_VAR_gke_cluster_node_count=1
export TF_VAR_admin_username={admin username}
export TF_VAR_admin_password={admin password}
export TF_VAR_windows_username=azarc-admin
export TF_VAR_windows_password={admin password}
export TF_VAR_SPN_CLIENT_ID={client id}
export TF_VAR_SPN_CLIENT_SECRET={client secret}
export TF_VAR_SPN_TENANT_ID={tenant id}
export TF_VAR_SPN_AUTHORITY=https://login.microsoftonline.com
export TF_VAR_AZDATA_USERNAME=arcdemo
export TF_VAR_AZDATA_PASSWORD={admin password}
export TF_VAR_ARC_DC_NAME=gkearcdatapgsqlctrl
export TF_VAR_ARC_DC_SUBSCRIPTION={subscription id}
export TF_VAR_ARC_DC_RG={resource group}
EOF

arc_data_gke_rg_name="rg-${appName}-data-gke-pgsql-${location}" 

sed -i "s/{gcp project id}/${GKE_DATA_PROJECT_ID}/g" ./scripts/vars.sh
sed -i "s/{admin username}/azarc-admin/g" ./scripts/vars.sh
sed -i "s/{admin password}/${ADM_PWD}/g" ./scripts/vars.sh
sed -i "s/{subscription id}/${subId}/g" ./scripts/vars.sh
sed -i "s/{client id}/${arc_data_sp_id}/g" ./scripts/vars.sh
sed -i "s/{client secret}/${arc_data_sp_password}/g" ./scripts/vars.sh
sed -i "s/{tenant id}/${tenantId}/g" ./scripts/vars.sh
sed -i "s/{resource group}/${arc_data_gke_rg_name}/g" ./scripts/vars.sh

cat ./scripts/vars.sh
source ./scripts/vars.sh
```

make sure your SSH keys are available in ~/.ssh and named id_rsa.pub and id_rsa. If you followed the ssh-keygen guide above to create your key then this should already be setup correctly. If not, you may need to modify main.tf to use a key with a different path.
TF does **NOT** support Passphrase
```sh
# Note: if your SSH Key is protected by a Passphrase, you will get an error mesage :
# Error: Failed to read ssh private key: password protected keys are not supported. Please decrypt the key prior to use.
# https://github.com/hashicorp/terraform/issues/13734
# https://github.com/hashicorp/terraform/issues/24898
ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa -C "youremail@groland.grd"

cd azure_arc_data_jumpstart/gke/postgres_hs/terraform
terraform init
# terraform plan
terraform apply --auto-approve

#if you goit thise error:
Error: googleapi: Error 400: Basic authentication was removed for GKE cluster versions >= 1.19. The cluster cannot be created with basic authentication enabled. Instructions for choosing an alternative authentication method can be found at: https://cloud.google.com/kubernetes-engine/docs/how-to/api-server-authentication., badRequest

==> then try to modify issue_client_certificate = false to issue_client_certificate = true in azure_arc_data_jumpstart/gke/postgres_hs/terraform/gke_cluster.tf

Then I hit
Error: googleapi: Error 400: Clusters with minor version 1.18 and basic authentication enabled cannot migrate to rapid, regular or stable release channels. Basic authentication was removed for GKE cluster versions >= 1.19. To disable basic authentication use: `gcloud container clusters update %s --no-enable-basic-auth`. Instructions for choosing a new method can be found at: https://cloud.google.com/kubernetes-engine/docs/how-to/api-server-authentication., badRequest

See 
https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool

gcp_vm_ip=$(terraform output |  tr -d '"'  |  tr -d 'ip =') 
rdp azarc-admin@$gcp_vm_ip

# manual GKE creation
# https://docs.microsoft.com/en-us/azure/azure-arc/data/sizing-guidance#minimum-deployment-requirements

gcloud container clusters create gke-arc-data-enabled --project $GKE_DATA_PROJECT_ID \
    --zone=$GKE_ZONE \
    --node-locations=$GKE_ZONE \
    --disk-type=pd-ssd \
    --disk-size=50GB \
    --machine-type=n2-standard-4 \
    --num-nodes=3 \
    --image-type ubuntu

# check at https://console.cloud.google.com/kubernetes/list?project=$GKE_DATA_PROJECT_ID 
# you may verified that 2 nodes have been created into the default nodepool, 1 per zone if you did create cluster with --zone europe-west4

gcloud container clusters list --project $GKE_DATA_PROJECT_ID 
gcloud container clusters get-credentials $GKE_DATA_PROJECT --zone $GKE_ZONE --project $GKE_DATA_PROJECT_ID

cat gke-config
cat ~/.kube/config
k config view --minify
k config get-contexts
k cluster-info

k create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)

azure_arc_ns="azure-arc"

# Deploy Azure Arc Agents for Kubernetes using Helm 3, into the azure-arc namespace
az connectedk8s connect --name $azure_arc_gke --infrastructure gcp -l $location -g $gke_rg_name

# verify
az connectedk8s list --subscription $subId -o table
az connectedk8s list -g $gke_rg_name -o table

ADSExtensionName="ads-extension"

# -o tsv is MANDATORY to remove quotes
azure_arc_gke_id=$(az connectedk8s show --name $azure_arc_gke -g $gke_rg_name -o tsv --query id)

az k8s-extension create --name ${ADSExtensionName} -c ${azure_arc_gke} -g ${gke_rg_name} --cluster-type connectedClusters --extension-type microsoft.arcdataservices --auto-upgrade false --scope cluster --release-namespace arc --config Microsoft.CustomLocation.ServiceAccount=sa-bootstrapper

az k8s-extension show --name ${ADSExtensionName} -g ${gke_rg_name} -c ${azure_arc_gke}  --cluster-type connectedclusters


export clNamespace=arc
export extensionId=$(az k8s-extension show -g ${gke_rg_name} -c ${azure_arc_gke} --cluster-type connectedClusters --name ${ADSExtensionName} --query id -o tsv)

az customlocation create -g ${gke_rg_name} -n "my-data-ship"  --namespace ${clNamespace} \
  --host-resource-id ${azure_arc_gke_id} \
  --cluster-extension-ids ${extensionId} --location westeurope

az customlocation list -o table
```


### Create the Azure Arc data controller
After the extension and custom location are created, proceed to Azure portal to deploy the Azure Arc data controller.

Log into the Azure portal.
Search for "Azure Arc data controller" in the Azure Marketplace and initiate the Create flow.
In the Prerequisites section, ensure that the Azure Arc enabled Kubernetes cluster (direct mode) is selected and proceed to the next step.
In the Data controller details section, choose a subscription and resource group.
Enter a name for the data controller.
Choose a configuration profile based on the Kubernetes distribution provider you are deploying to.
Choose the Custom Location that you created in the previous step.
Provide details for the data controller administrator login and password.
Provide details for ClientId, TenantId, and Client Secret for the Service Principal that would be used to create the Azure objects. See Upload metrics for detailed instructions on creating a Service Principal account and the roles that needed to be granted for the account.
Click Next, review the summary page for all the details and click on Create.

```sh
az monitor log-analytics workspace list
az monitor log-analytics workspace create -n $analytics_workspace_name --location $location -g $gke_rg_name --verbose
az monitor log-analytics workspace list
az monitor log-analytics workspace show -n $analytics_workspace_name -g $gke_rg_name --verbose

export analytics_workspace_id=$(az monitor log-analytics workspace show -n $analytics_workspace_name -g $gke_rg_name -o tsv --query id)
echo "analytics_workspace_id:" $analytics_workspace_id

k get datacontrollers -n arc

```

### Create an Azure Arc enabled PostgreSQL Hyperscale server group

see [https://kubernetes.io/docs/concepts/storage/storage-classes/#gce-pd](https://kubernetes.io/docs/concepts/storage/storage-classes/#gce-pd)

```sh
azdata login
azdata arc postgres server create --help

# only AccessModes [ReadWriteOnce ReadOnlyMany] are supported
cat <<EOF >> deploy/GKE_BackupPVC.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: arc
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 100Gi
  storageClassName: standard
EOF

cat deploy/GKE_BackupPVC.yaml
k apply -f deploy/GKE_BackupPVC.yaml
k get pvc -n arc

# --storage-class-backups means “Use this storage class to create backup volumes for me.” “-vcm x:backup” means “Don’t create backup volumes for #me. Use this pre-existing volume.”
# The two options are in conflict.

azdata arc postgres server create -n postgres01 --workers 2 --engine-version 12 \
-vcm backup-pvc:backup \
--storage-class-data standard-rwo \
--storage-class-logs standard-rwo

azdata arc postgres server list
azdata arc postgres endpoint list -n postgres01

```

### Back up and restore Azure Arc enabled PostgreSQL Hyperscale server groups

See [https://docs.microsoft.com/en-us/azure/azure-arc/data/backup-restore-postgresql-hyperscale](https://docs.microsoft.com/en-us/azure/azure-arc/data/backup-restore-postgresql-hyperscale)

```sh

azdata arc postgres backup create --name backup_pg_20210608-0900am --server-name postgres01
azdata arc postgres backup list --server-name postgres01

# get the backup ID for restore : 
azdata arc postgres backup show --name backup_pg_20210608-0900am --server-name postgres01

# Restore the server group postgres01 onto itself:
azdata arc postgres backup restore -sn postgres01 --backup-id d134f51aa87f4044b5fb07cf95cf797f


```


## Deploy an Azure SQL Managed Instance on GKE using a Terraform plan

See [https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/gke/gke_mssql_mi_terraform/#deploy-an-azure-sql-managed-instance-on-gke-using-a-terraform-plan](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/gke/gke_mssql_mi_terraform/#deploy-an-azure-sql-managed-instance-on-gke-using-a-terraform-plan)

## Pre-req

Ensure to have the GCP project, SA et keys created ax described in the previous [pre-req section](#GCP-Pre-req)

## Deploy IaC with TF

Edit scripts/vars.sh and update each of the variables with the appropriate values.
see azure_arc_data_jumpstart/gke/mssql_mi/terraform/example/TF_VAR_example.sh


```sh
cd azure_arc_data_jumpstart/gke/mssql_mi/terraform
cp ~/gke-arc-data-sa-key.json azure_arc_data_jumpstart/gke/mssql_mi/terraform

cat <<EOF >> scripts/vars.sh
export TF_VAR_gcp_project_id={gcp project id}
export TF_VAR_gcp_credentials_filename=gke-arc-data-sa-key.json
export TF_VAR_gcp_region=europe-west4
export TF_VAR_gcp_zone=${GKE_ZONE}
export TF_VAR_ARC_DC_REGION=westeurope
export TF_VAR_gke_cluster_name=arc-sql-data-gke
export TF_VAR_gke_cluster_node_count=1
export TF_VAR_admin_username={admin username}
export TF_VAR_admin_password={admin password}
export TF_VAR_windows_username=azarc-admin
export TF_VAR_windows_password={admin password}
export TF_VAR_SPN_CLIENT_ID={client id}
export TF_VAR_SPN_CLIENT_SECRET={client secret}
export TF_VAR_SPN_TENANT_ID={tenant id}
export TF_VAR_SPN_AUTHORITY=https://login.microsoftonline.com
export TF_VAR_AZDATA_USERNAME=arcdemo
export TF_VAR_AZDATA_PASSWORD={admin password}
export TF_VAR_ARC_DC_NAME=gkearcdatasqlmictrl
export TF_VAR_ARC_DC_SUBSCRIPTION={subscription id}
export TF_VAR_ARC_DC_RG={resource group}
EOF

arc_data_gke_rg_name="rg-${appName}-data-gke-sqlmi-${location}" 

sed -i "s/{gcp project id}/${GKE_DATA_PROJECT_ID}/g" ./scripts/vars.sh
sed -i "s/{admin username}/azarc-admin/g" ./scripts/vars.sh
sed -i "s/{admin password}/${ADM_PWD}/g" ./scripts/vars.sh
sed -i "s/{subscription id}/${subId}/g" ./scripts/vars.sh
sed -i "s/{client id}/${arc_data_sp_id}/g" ./scripts/vars.sh
sed -i "s/{client secret}/${arc_data_sp_password}/g" ./scripts/vars.sh
sed -i "s/{tenant id}/${tenantId}/g" ./scripts/vars.sh
sed -i "s/{resource group}/${arc_data_gke_rg_name}/g" ./scripts/vars.sh

cat ./scripts/vars.sh
source ./scripts/vars.sh
```

make sure your SSH keys are available in ~/.ssh and named id_rsa.pub and id_rsa. If you followed the ssh-keygen guide above to create your key then this should already be setup correctly. If not, you may need to modify main.tf to use a key with a different path.
TF does **NOT** support Passphrase
```sh
# Note: if your SSH Key is protected by a Passphrase, you will get an error mesage :
# Error: Failed to read ssh private key: password protected keys are not supported. Please decrypt the key prior to use.
# https://github.com/hashicorp/terraform/issues/13734
# https://github.com/hashicorp/terraform/issues/24898
ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa -C "youremail@groland.grd"

cd azure_arc_data_jumpstart/gke/mssql_mi/terraform
terraform init
# terraform plan
terraform apply --auto-approve

gcp_vm_ip=$(terraform output |  tr -d '"'  |  tr -d 'ip =') 
rdp azarc-admin@$gcp_vm_ip

```

## Toubleshoot

If you see the error below : 
Error: Error creating instance: googleapi: Error 400: Windows VM instancs are not included with the free trial. To use them, first enable billing on your account. You'll still be able to apply your free trial credits to eligible products and services., windowsVmNotAllowedInFreeTrialProject

  on client_vm.tf line 23, in resource "google_compute_instance" "default":
  23: resource "google_compute_instance" "default" {


==> Check the billing account is correctly linked to the GCP project, then enable the GCP full access clicking on the top of the google cloud console where there is a link appearing to enable usage of free credit then rerun : 
terraform apply --auto-approve

Note: To connect to the Postgres instance use the AZDATA_USERNAME and AZDATA_PASSWORD values specified in the azuredeploy.parameters.json file. The “sa” login is disabled.

On the windows client VM
```sh
$env:ARC_DC_NAME
azdata login --namespace $env:ARC_DC_NAME
azdata arc dc status show

kubectl get ns
kubectl get pods -n $env:ARC_DC_NAME

kubectl get events --all-namespaces
kubectl get rs -n gkearcdatactrl
kubectl describe rs bootstrapper -n $env:ARC_DC_NAME

kubectl get sa -n $env:ARC_DC_NAME
kubectl get sa --all-namespaces

kubectl describe sa default -n $env:ARC_DC_NAME
gcloud container clusters describe arc-data-gke --zone europe-west4-a
kubectl get secrets --all-namespaces

# To check your env variables : 

dir env:
```

# Clean-Up
[https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_dc_vanilla_arm_template/#cleanup](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_dc_vanilla_arm_template/#cleanup)

**IMPORTANT**
To delete the Azure Arc Data Controller and all of it’s Kubernetes resources, run the DC_Cleanup.ps1 PowerShell script located in C:\tmp on the Windows Client VM. At the end of it’s run, the script will close all PowerShell sessions. The Cleanup script run time is approximately 5min long.

```sh
## Workaround
# Check first your KubeConfig

k config get-contexts
k config view --minify

# AKS
C:\tmp\DC_Cleanup.ps1
C:\tmp\Postgres_Cleanup.ps1

azdata arc dc delete -ns arcdatactrl -n arcdatactrl
az resource delete --name arcdatactrl --resource-type Microsoft.AzureData/dataControllers --resource-group rg-azarc-data-aks-pgsql-westeurope

az deployment group delete --name azarc-data-aks-pgsql -g rg-azarc-data-aks-pgsql-westeurope

az resource delete --ids /subscriptions/$subId/resourceGroups/rg-azarc-data-aks-pgsql-westeurope/providers/Microsoft.AzureArcData/dataControllers/arcdatactrl --resource-type Microsoft.AzureData/dataControllers -g rg-azarc-data-aks-pgsql-westeurope

kubectl config delete-context XXX-ctx
az group delete -n rg-azarc-data-aks-pgsql-westeurope

# GKE
C:\tmp\Postgres_HS_Cleanup.ps1

azdata arc dc delete -ns arcdatactrl -n gkearcdatactrl
az resource delete --name gkearcdatactrl --resource-type Microsoft.AzureData/dataControllers -g $arc_data_gke_rg_name

az resource delete --ids /subscriptions/$subId/resourceGroups/$arc_data_gke_rg_name/providers/Microsoft.AzureArcData/dataControllers/gkearcdatactrl --resource-type Microsoft.AzureData/dataControllers -g $arc_data_gke_rg_name

# TF
terraform destroy --auto-approve

```