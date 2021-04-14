See :
- [https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_postgresql_hyperscale_arm_template](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_postgresql_hyperscale_arm_template/)
- [https://docs.microsoft.com/en-us/azure/azure-arc/data/overview](https://docs.microsoft.com/en-us/azure/azure-arc/data/overview)

# Pre-req

Install [client tools](https://docs.microsoft.com/en-us/azure/azure-arc/data/install-client-tools)

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
az aks get-versions -l $location

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
az aks get-versions -l $location

arc_data_aks_rg_name="rg-${appName}-data-aks-pgsql-${location}" 

az group create --name $arc_data_aks_rg_name --location $location

az deployment group create --name azarc-data-aks-pgsql \
--resource-group $arc_data_aks_rg_name \
--name ${appName}-data-aks-pgsql \
--template-uri https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_data_jumpstart/aks/arm_template/postgres_hs/azuredeploy.json \
--parameters azure_arc_data_jumpstart/aks/arm_template/postgres_hs/azuredeploy.parameters.json
```


# Deploy an Azure PostgreSQL Hyperscale Deployment on GKE using a Terraform plan

[https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/gke/gke_postgres_hs_terraform/#deploy-an-azure-postgresql-hyperscale-deployment-on-gke-using-a-terraform-plan](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/gke/gke_postgres_hs_terraform/#deploy-an-azure-postgresql-hyperscale-deployment-on-gke-using-a-terraform-plan)


## Pre-req
```sh
gcloud version
sudo /home/$USER/google-cloud-sdk/bin/gcloud components update

gcloud auth login $GKE_ACCOUNT

gcloud config list
gcloud config set account $GKE_ACCOUNT
GKE_DATA_PROJECT_ID="$GKE_DATA_PROJECT-$(uuidgen | cut -d '-' -f2 | tr '[A-Z]' '[a-z]')"
gcloud projects create $GKE_DATA_PROJECT_ID --name $GKE_DATA_PROJECT --verbosity=info
gcloud projects list 
gcloud config set project $GKE_DATA_PROJECT_ID

# You need to enable GKE API, see at https://console.cloud.google.com/apis/api/container.googleapis.com/overview?project=gke-arc-enabled
echo "You need to enable GKE API, see at https://console.cloud.google.com/apis/api/container.googleapis.com/overview?project=$GKE_DATA_PROJECT_ID"
# https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster
# https://cloud.google.com/compute/docs/machine-types ==> n1-standard-1 is too small

```

Next, set up a service account key, which Terraform will use to create and manage resources in your GCP project. Go to the create service account key page. Select “New Service Account” from the dropdown, give it a name, select Project then Owner as the role, JSON as the key type, and click Create. This downloads a JSON file with all the credentials that will be needed for Terraform to manage the resources. Copy the downloaded JSON file to the azure_arc_servers_jumpstart/gcp/ubuntu/terraform directory.

[https://cloud.google.com/iam/docs/creating-managing-service-account-keys](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)

```sh
gcloud iam service-accounts create sa-azure-arc-data --display-name="Azure Arc for Data Service Account" --description="Azure Arc for Data Service Account"
gcloud iam service-accounts list
gcloud iam service-accounts describe sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com | grep -i "uniqueId: "

gcloud iam service-accounts keys create ~/gke-arc-data-sa-key.json --iam-account sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts keys list --iam-account sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com

gcloud container clusters list --project $GKE_DATA_PROJECT_ID
gcloud config set project $GKE_DATA_PROJECT
gcloud config list
# These flags are available to all commands: --account, --billing-project, --configuration, --flags-file, --flatten, --format, --help, --impersonate-service-account, --log-http, --project, --quiet, --trace-token, --user-output-enabled, --verbosity.

gcloud container clusters list --project $GKE_DATA_PROJECT_ID


cd azure_arc_data_jumpstart/gke/postgres_hs/terraform/

gcloud container get-server-config --zone $GKE_ZONE

# RG will be created by TF
# arc_data_gke_rg_name="rg-${appName}-data-gke-pgsql-${location}" 
# az group create --name $arc_data_gke_rg_name --location $location

```

## Deploy IaC with TF

Edit scripts/vars.sh and update each of the variables with the appropriate values.
see azure_arc_data_jumpstart/gke/postgres_hs/terraform/example/TF_VAR_example.sh


```sh
cat <<EOF >> scripts/vars.sh
export TF_VAR_gcp_project_id={gcp project id}
export TF_VAR_gcp_credentials_filename=~/gke-arc-data-sa-key.json
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
export TF_VAR_ARC_DC_NAME=gkearcdatactrl
export TF_VAR_ARC_DC_SUBSCRIPTION={subscription id}
export TF_VAR_ARC_DC_RG={resource group}
EOF

sed -i "s/{gcp project id}/${GKE_DATA_PROJECT_ID}/g" vars.sh
sed -i "s/{admin username}/azarc-admin/g" vars.sh
sed -i "s/{admin password}/${ADM_PWD}/g" vars.sh
sed -i "s/{subscription id}/${subId}/g" vars.sh
sed -i "s/{client id}/${arc_data_sp_id}/g" vars.sh
sed -i "s/{client secret}/${arc_data_sp_password}/g" vars.sh
sed -i "s/{tenant id}/${tenantId}/g" vars.sh
sed -i "s/{resource group}/${arc_data_gke_rg_name}/g" vars.sh


cat vars.sh
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
```


```sh

# If you get this error :  googleapi: Error 403: Required 'compute.zones.get' permission for 'projects/
# https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/issues/459
# https://stackoverflow.com/questions/48232189/google-compute-engine-required-compute-zones-get-permission-error
# requires roles: roles/compute.instanceAdmin , roles/editor , roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $GKE_DATA_PROJECT_ID \
    --member="serviceAccount:sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.instanceAdmin"

gcloud projects add-iam-policy-binding $GKE_DATA_PROJECT_ID \
    --member="serviceAccount:sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"

gcloud projects add-iam-policy-binding $GKE_DATA_PROJECT_ID \
    --member="serviceAccount:sa-azure-arc-data@$GKE_DATA_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

cd azure_arc_data_jumpstart/gke/postgres_hs/terraform

terraform init
# terraform plan
terraform apply --auto-approve

gcp_vm_ip=$(terraform output |  tr -d '"'  |  tr -d 'ip =') 
rdp azarc-admin@$gcp_vm_ip

```

### Toubleshoot

If you see the error below : 
Error: Error creating instance: googleapi: Error 400: Windows VM instances are not included with the free trial. To use them, first enable billing on your account. You'll still be able to apply your free trial credits to eligible products and services., windowsVmNotAllowedInFreeTrialProject

  on client_vm.tf line 23, in resource "google_compute_instance" "default":
  23: resource "google_compute_instance" "default" {


==> Check the billing account is correctly linked to the GCP project, then enable the GCP full access clicking on the top of the google cloud console where there is a link appearing to enable usage of free credit then rerun : 

terraform apply --auto-approve




# Clean-Up
[https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_dc_vanilla_arm_template/#cleanup](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_data/aks/aks_dc_vanilla_arm_template/#cleanup)

**IMPORTANT**
To delete the Azure Arc Data Controller and all of it’s Kubernetes resources, run the DC_Cleanup.ps1 PowerShell script located in C:\tmp on the Windows Client VM. At the end of it’s run, the script will close all PowerShell sessions. The Cleanup script run time is approximately 5min long.


## Workaround
Check first your KubeConfig
```sh
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

terraform destroy --auto-approve

```