
[https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/azure/azure_arm_template_linux/](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/azure/azure_arm_template_linux/)

# Pre-req
```sh
arc_server_sp_password=$(az ad sp create-for-rbac --name $appName-server --role contributor --query password -o tsv)
echo $arc_server_sp_password > arc_server_sp_password.txt
echo "Service Principal Password saved to ./arc_server_sp_password.txt IMPORTANT Keep your password ..." 
# arc_server_sp_password=`cat arc_server_sp_password.txt`
arc_server_sp_id=$(az ad sp show --id http://$appName-server --query appId -o tsv)
#arc_server_sp_id=$(az ad sp list --all --query "[?appDisplayName=='${appName}-server'].{appId:appId}" --output tsv)
#arc_server_sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}-server'].{appId:appId}" -o tsv)
echo "Arc for Server Service Principal ID:" $arc_server_sp_id 
echo $arc_server_sp_id > arc_server_sp_id.txt
# arc_server_sp_id=`cat arc_server_sp_id.txt`
az ad sp show --id $arc_server_sp_id
```

# Deploy Azure VM
```sh
git clone https://github.com/microsoft/azure_arc.git

az group create --name rg-${appName}-servers-${location} --location $location --tags "Project=jumpstart_azure_arc_servers"

az deployment group create \
--resource-group rg-${appName}-servers-${location} \
--name arclinuxdemo  \
--template-uri https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_servers_jumpstart/azure/linux/arm_template/azuredeploy.json \
--parameters ./cnf/arc-server.azuredeploy.parameters.json

```

## Connect to the VM
At first login, as mentioned in the “Automation Flow” section, a logon script will get executed. This script was created as part of the automated deployment process.
Let the script to run its course and do not close the SSH session, this will be done for you once completed.

```sh
ssh azarc-admin@<the VM public IP>

```

If you see the here under error :
ERROR[0000] Failed to AzcmagentConnect ARM resource       Error="RequestCorrelationId:6d574a85-8040-4cc2-ad53-102e15cadaca Message: The subscription is not registered to use namespace 'Microsoft.HybridCompute'. See https://aka.ms/rps-not-found for how to register subscriptions. Code: MissingSubscriptionRegistration httpStatusCode:409 "
FATAL[0000] RequestCorrelationId:6d574a85-8040-4cc2-ad53-102e15cadaca Message: The subscription is not registered to use namespace 'Microsoft.HybridCompute'. See https://aka.ms/rps-not-found for how to register subscriptions. Code: MissingSubscriptionRegistration httpStatusCode:409

See [https://docs.microsoft.com/en-us/azure/azure-arc/servers/learn/quick-enable-hybrid-vm#register-azure-resource-providers](https://docs.microsoft.com/en-us/azure/azure-arc/servers/learn/quick-enable-hybrid-vm#register-azure-resource-providers)
```sh
az provider register --namespace 'Microsoft.HybridCompute'
az provider register --namespace 'Microsoft.GuestConfiguration'
```

# Deploy VM to GCP

[https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/gcp/gcp_terraform_ubuntu](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/gcp/gcp_terraform_ubuntu)


## Pre-req
```sh
gcloud auth login $GKE_ACCOUNT
# sudo /home/$USER/google-cloud-sdk/bin/gcloud components update

gcloud config list
gcloud config set account $GKE_ACCOUNT

GCP_PROJECT_ID="$GCP_PROJECT-$(uuidgen | cut -d '-' -f2 | tr '[A-Z]' '[a-z]')"
gcloud projects create $GCP_PROJECT_ID --name $GCP_PROJECT --verbosity=info
gcloud projects list 
gcloud compute instances list --project $GCP_PROJECT
gcloud config set project $GCP_PROJECT_ID
gcloud config list

# Once the new project is created and selected in the dropdown at the top of the page, you must enable Compute Engine API access for the project. Click on “+Enable APIs and Services” and search for “Compute Engine”. Then click Enable to enable API access.

# see at https://console.cloud.google.com/apis/api/compute.googleapis.com/overview?project=gcp-vm-arc-enabled
echo "You need to enable GCP Compute Engine API, see at https://console.cloud.google.com/apis/api/compute.googleapis.com/overview?project=$GCP_PROJECT_ID"
# https://cloud.google.com/compute/docs/machine-types


```

Next, set up a service account key, which Terraform will use to create and manage resources in your GCP project. Go to the create service account key page. Select “New Service Account” from the dropdown, give it a name, select Project then Owner as the role, JSON as the key type, and click Create. This downloads a JSON file with all the credentials that will be needed for Terraform to manage the resources. Copy the downloaded JSON file to the azure_arc_servers_jumpstart/gcp/ubuntu/terraform directory.

[https://cloud.google.com/iam/docs/creating-managing-service-account-keys](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)
```sh

gcloud iam service-accounts create sa-azure-arc --display-name="Azure Arc for servers Service Account" --description="Azure Arc for servers Service Account"
gcloud iam service-accounts list

gcloud iam service-accounts keys create ~/gcp-sa-key.json --iam-account sa-azure-arc@$GCP_PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts keys list --iam-account sa-azure-arc@$GCP_PROJECT_ID.iam.gserviceaccount.com

```

make sure your SSH keys are available in ~/.ssh and named id_rsa.pub and id_rsa. If you followed the ssh-keygen guide above to create your key then this should already be setup correctly. If not, you may need to modify main.tf to use a key with a different path.

Edit scripts/vars.sh and update each of the variables with the appropriate values.

TF_VAR_subscription_id=Your Azure subscription ID
TF_VAR_client_id=Your Azure service principal app id
TF_VAR_client_secret=Your Azure service principal password
TF_VAR_tenant_id=Your Azure tenant ID
TF_VAR_gcp_project_id=GCP project id
TF_VAR_gcp_credentials_filename=GCP credentials json filename


```sh
sed -i "s/{subscription id}/${subId}/g" vars.sh
sed -i "s/{client id}/${arc_server_sp_id}/g" vars.sh
sed -i "s/{client secret}/${arc_server_sp_password}/g" vars.sh
sed -i "s/{tenant id}/${tenantId}/g" vars.sh
sed -i "s/{gcp project id}/${GCP_PROJECT_ID}/g" vars.sh
sed -i "s/{gcp credentials path}/~\/gcp-sa-key.json/g" vars.sh

cat vars.sh
source ./scripts/vars.sh
```

```sh
terraform init
terraform apply --auto-approve

gcp_vm_ip=$(terraform output)
ssh arcadmin@$gcp_vm_ip

```