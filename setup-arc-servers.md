
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
gcloud version
sudo /home/$USER/google-cloud-sdk/bin/gcloud components update

gcloud auth login $GKE_ACCOUNT

gcloud config list
gcloud config set account $GKE_ACCOUNT

GCP_PROJECT_ID="$GCP_PROJECT-$(uuidgen | cut -d '-' -f2 | tr '[A-Z]' '[a-z]')"
gcloud projects create $GCP_PROJECT_ID --name $GCP_PROJECT --verbosity=info
gcloud projects list 
gcloud compute instances list --project $GCP_PROJECT_ID
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
gcloud iam service-accounts describe sa-azure-arc@$GCP_PROJECT_ID.iam.gserviceaccount.com | grep -i "uniqueId: "

gcloud iam service-accounts keys create ~/gcp-sa-key.json --iam-account sa-azure-arc@$GCP_PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts keys list --iam-account sa-azure-arc@$GCP_PROJECT_ID.iam.gserviceaccount.com

```

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


cat <<EOF >> vars.sh

export TF_VAR_gcp_region=europe-west4
export TF_VAR_gcp_zone=${GKE_ZONE}
export TF_VAR_admin_username=azarc-admin
export TF_VAR_admin_password=GrogeuleArcJump666!
export TF_VAR_azure_location=${location} 
export TF_VAR_azure_resource_group=rg-${appName}-servers-gcp
EOF

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

cd azure_arc_servers_jumpstart/gcp/ubuntu/terraform

terraform init
terraform plan
terraform apply --auto-approve

# If you get this error :  googleapi: Error 403: Required 'compute.zones.get' permission for 'projects/
# https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/issues/459
# https://stackoverflow.com/questions/48232189/google-compute-engine-required-compute-zones-get-permission-error
# requires roles: roles/compute.instanceAdmin , roles/editor , roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member="serviceAccount:sa-azure-arc@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.instanceAdmin"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member="serviceAccount:sa-azure-arc@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member="serviceAccount:sa-azure-arc@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"



gcp_vm_ip=$(terraform output |  tr -d '"'  |  tr -d 'ip =') 
ssh azarc-admin@$gcp_vm_ip

```

# Unified Operations Use Cases

## Update Management

[https://docs.microsoft.com/en-us/azure/automation/update-management/overview](https://docs.microsoft.com/en-us/azure/automation/update-management/overview)

```sh

#  create a Log Analytics workspace
az group create --name rg-arc-update-management --location $location \
--tags "Project=jumpstart_azure_arc_servers"

# To deploy the ARM template, navigate to the deployment folder and run the below command:
az deployment group create --resource-group rg-arc-update-management \
    --template-file law-template.json \
    --parameters law-template.parameters.json

```

## Azure Policy

[https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/day2/arc_policies_mma](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/day2/arc_policies_mma)

move to the Deployment Directory at [https://github.com/microsoft/azure_arc/tree/main/azure_arc_servers_jumpstart/policies/arm](https://github.com/microsoft/azure_arc/tree/main/azure_arc_servers_jumpstart/policies/arm)

You will also need to have a Log Analytics workspace deployed. You can automate the deployment by editing the ARM template parameters file, provide a name and location for your workspace.

```sh
az deployment group create --resource-group rg-${appName}-servers-gcp \
  --template-file policies/arm/log_analytics-template.json \
  --parameters policies/arm/log_analytics-template.parameters.json
```

Now that you have all the prerequisites set, you can assign policies to our Arc connected machines. Edit the parameters file to provide your subscription ID as well as the Log Analytics workspace.

```sh

az policy assignment create --name 'Enable Azure Monitor for VMs' \
--scope '/subscriptions/$subId/resourceGroups/rg-$appName-servers-gcp' \
--policy-set-definition '55f3eceb-5573-4f18-9695-226972c6d74a' \
-p policies/arm/policy.json \
--assign-identity --location $location

```

See also [Azure Compute Built-in Policies](https://docs.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies#compute) 


## Azure Security Center

[https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/day2/arc_securitycenter](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/day2/arc_securitycenter)

Data collected by Azure Security Center is stored in a Log Analytics workspace. You can either use the default one created by ASC or a custom one created by you. If you want to create a dedicated workspace, you can automate the deployment by editing the ARM template parameters file, provide a name and location for your workspace:

```sh

az deployment group create --resource-group rg-${appName}-servers-gcp \
  --template-file securitycenter/arm/log_analytics-template.json \
  --parameters securitycenter/arm/log_analytics-template.parameters.json

az security workspace-setting create --name default \
  --target-workspace '/subscriptions/<Your subscription ID>/resourceGroups/<Name of the Azure resource group>/providers/Microsoft.OperationalInsights/workspaces/<Name of the Log Analytics Workspace>'

```

Select the Azure Security Center tier. The Free tier is enabled on all your Azure subscriptions by default and will provide continuous security assessment and actionable security recommendations. In this guide, you will use the Standard tier for Virtual Machines that extends these capabilities providing unified security management and threat protection across your hybrid cloud workloads. To enable the Standard tier of Azure Security Center for VMs run the command below:

```sh
az security pricing create -n VirtualMachines --tier 'standard'
```

Now you need to assign the default Security Center policy initiative. ASC makes its security recommendations based on policies. There is an specific initiative that groups Security Center policies with the definition ID ‘1f3afdf9-d0c9-4c3d-847f-89da613e70a8’. The command below will assign the ASC initiative to your subscription:
```sh
az policy assignment create --name 'ASC Default <Your subscription ID>' \
--scope '/subscriptions/<Your subscription ID>' \
--policy-set-definition '1f3afdf9-d0c9-4c3d-847f-89da613e70a8'
```

In the “Compute & apps” section under “VM and Servers”, ASC will provide you with an overview of all the discovered security recommendations for your VMs and computers, including Azure VMs, Azure Classic VMs, servers and Azure Arc Machines.



## Apply inventory tagging to Azure Arc enabled servers

[https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/day2/arc_inventory_tagging](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/day2/arc_inventory_tagging)


Enter “Resource Graph Explorer” in the top search bar in the Azure portal and select it.
In the query window, enter the following query and then click “Run Query”:
```sh
Resources
| where type =~ 'Microsoft.HybridCompute/machines'
```

Create a basic Azure tag taxonomy

```sh
az tag create --name "Hosting Platform"
az tag add-value --name "Hosting Platform" --value "Azure"
az tag add-value --name "Hosting Platform" --value "AWS"
az tag add-value --name "Hosting Platform" --value "GCP"
az tag add-value --name "Hosting Platform" --value "On-premises"
```

[Tag Arc-connected GCP Ubuntu server](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/day2/arc_inventory_tagging/#tag-arc-connected-gcp-ubuntu-server)
```sh
export gcpResourceGroup="arc-gcp-demo"
export gcpMachineName="arc-gcp-demo"
export gcpMachineResourceId="$(az resource show --resource-group rg-${appName}-servers-gcp --name arc-gcp-demo --resource-type "Microsoft.HybridCompute/machines" --query id)"
export gcpMachineResourceId="$(echo $gcpMachineResourceId | tr -d "\"" | tr -d '\r')"
az resource tag --resource-group rg-${appName}-servers-gcp --ids $gcpMachineResourceId --tags "Hosting Platform"="GCP"

# Use '' to clear existing tags.
# az resource tag --resource-group rg-${appName}-servers-gcp --ids $gcpMachineResourceId --tags ''
```

Query resources by tag using Resource Graph Explorer. In the query window, enter the following query:
```sh
Resources
| where type =~ 'Microsoft.HybridCompute/machines'
| where isnotempty(tags['Hosting Platform'])
| project name, location, resourceGroup, tags
```


## Enable Change Tracking and Inventory

[https://docs.microsoft.com/en-us/azure/automation/change-tracking/overview](https://docs.microsoft.com/en-us/azure/automation/change-tracking/overview)

```sh
sudo apt-get update
sudo apt-get install -y python2
python -h
python -V

```

## Deploy Monitoring Agent Extension on Azure Arc Linux and Windows servers using Extension Management
```sh
az deployment group create --resource-group rg-${appName}-servers-gcp \
  --template-file extensions/arm/log_analytics-template.json \
  --parameters extensions/arm/log_analytics-template.parameters.json

az monitor log-analytics workspace list
az monitor log-analytics workspace show -n log-azarc-mma -g rg-${appName}-servers-gcp --verbose

# -o tsv to manage quotes issues
mma_analytics_workspace_id=$(az monitor log-analytics workspace show -n log-azarc-mma -g rg-${appName}-servers-gcp --query id -o tsv)
echo "MMA analytics_workspace_id:" $mma_analytics_workspace_id

mma_analytics_workspace_key=$(az monitor log-analytics workspace get-shared-keys -n log-azarc-mma -g rg-${appName}-servers-gcp --query primarySharedKey -o tsv)
echo "MMA analytics_workspace_key:" $mma_analytics_workspace_key

# Edit the extensions parameters file at extensions/arm/mma-template.parameters.json to set workspace ID and key
az deployment group create --resource-group rg-${appName}-servers-gcp \
  --template-file extensions/arm/mma-template-linux.json \
  --parameters extensions/arm/mma-template.parameters.json


```

```sh

```