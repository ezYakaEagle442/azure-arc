# Naming conventions
See also [See also https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/naming-and-tagging](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/naming-and-tagging)

# Mardown docs

- [https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)
- [https://daringfireball.net/projects/markdown/](https://daringfireball.net/projects/markdown/)
- [https://docs.microsoft.com/en-us/contribute/markdown-reference](https://docs.microsoft.com/en-us/contribute/markdown-reference)

# Azure Cloud Shell

You can use the Azure Cloud Shell accessible at <https://shell.azure.com> once you login with an Azure subscription.
See also [https://azure.microsoft.com/en-us/features/cloud-shell/](https://azure.microsoft.com/en-us/features/cloud-shell/)

**/!\ IMPORTANT** Create a storage account for CloudShell in the Region where you plan to deploy your resources and accordingly.
Ex: run CloudShell in France Central Region if you plan do deploy your resources in France Central Region

**/!\ IMPORTANT** CloudShell session idle TimeOut is 20 minutes, you may find WSL/Powershell ISE more confortale.
[https://feedback.azure.com/forums/598699-azure-cloud-shell/suggestions/32240851-fix-increase-cloudshell-timeout](https://feedback.azure.com/forums/598699-azure-cloud-shell/suggestions/32240851-fix-increase-cloudshell-timeout)

[https://medium.com/@navneet.ts/azure-nugget-give-the-cloud-shell-timeout-a-timeout-c486dc544bc3](https://medium.com/@navneet.ts/azure-nugget-give-the-cloud-shell-timeout-a-timeout-c486dc544bc3)

## Uploading and editing files in Azure Cloud Shell

- You can use `vim <file you want to edit>` in Azure Cloud Shell to open the built-in text editor.
- You can upload files to the Azure Cloud Shell by dragging and dropping them
- You can also do a `curl -o filename.ext https://file-url/filename.ext` to download a file from the internet.

## You can Install [Chocolatey](https://chocolatey.org/install) on Windows
```sh
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

# Logs at C:\ProgramData\chocolatey\logs\chocolatey.log 
# Files cached at C:\Users\%USERNAME%\AppData\Local\Temp\chocolatey
```

## How to install Windows Subsystem for Linux (WSL)

```sh
# https://chocolatey.org/packages/wsl
choco install wsl --Yes --confirm --accept-license --verbose 
choco install wsl-ubuntu-1804 --Yes --confirm --accept-license --verbose

```

## Upgrade to to WSL 2
See [https://docs.microsoft.com/en-us/windows/wsl/install-win10#update-to-wsl-2](https://docs.microsoft.com/en-us/windows/wsl/install-win10#update-to-wsl-2)
Pre-req: Windows 10, updated to version 2004, **Build 19041** or higher.

```sh
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# reboot
wsl --set-default-version 2

# The update from WSL 1 to WSL 2 may take several minutes to complete depending on the size of your targeted distribution. If you are running an older (legacy) installation of WSL 1 from Windows 10 Anniversary Update or Creators Update, you may encounter an update error. Follow these instructions to uninstall and remove any legacy distributions.

wsl --list --verbose
wsl --set-version <distribution name> <versionNumber>

```

## Setup PowerShell in WSL
See :
- [https://docs.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7#ubuntu-1804](https://docs.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7#ubuntu-1804)
- [https://www.saggiehaim.net/powershell/install-powershell-7-on-wsl-and-ubuntu](https://www.saggiehaim.net/powershell/install-powershell-7-on-wsl-and-ubuntu)

https://github.com/PowerShell/PowerShell/blob/master/docs/building/linux.md

```sh
# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb

# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb

# Update the list of products
sudo apt-get update

# Enable the "universe" repositories
sudo add-apt-repository universe

# Install PowerShell
sudo apt-get install -y powershell

# restart WSL
pwsh

Get-PSRepository
Install-Module -Name Az

# Create Folder
# sudo mkdir /usr/share/PowerShell
# Change Working Dir
cd /usr/share/PowerShell

# https://github.com/PowerShell/PowerShell/releases/tag/v6.1.5
# sudo wget https://github.com/PowerShell/PowerShell/releases/download/v7.0.0-rc.2/powershell-7.0.0-rc.2-linux-x64.tar.gz
# sudo wget https://github.com/PowerShell/PowerShell/releases/download/v6.1.5/powershell-6.1.5-linux-alpine-x64.tar.gz
# sudo tar xzvf powershell-6.1.5-linux-alpine-x64.tar.gz
# sudo rm /usr/share/PowerShell/powershell-6.1.5-linux-alpine-x64.tar.gz

cd #HOME
 
# Edit the .profile file
vim .profile # PATH="$PATH:/usr/share/PowerShell"

# restart WSL
pwsh

```


## How to install tools into Subsystem for Linux (WSL)

```sh
sudo apt-get install -y apt-transport-https

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo touch /etc/apt/sources.list.d/kubernetes.list 
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
kubectl api-versions

```

## How to install Git bash for Windows 

```sh
# https://chocolatey.org/packages/git.install
# https://gitforwindows.org/
choco install git.install --Yes --confirm --accept-license

```
### Git Troubleshoot

[https://www.illuminiastudios.com/dev-diaries/ssh-on-windows-subsystem-for-linux](https://www.illuminiastudios.com/dev-diaries/ssh-on-windows-subsystem-for-linux)
[https://help.github.com/en/enterprise/2.20/user/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent](https://help.github.com/en/enterprise/2.20/user/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

Check the fingerprint of you SSH key in GitHub with the SSH Key used by git.

If your GIT repo URL starts with HTTPS (ex: "https://github.com/<!XXXyour-git-homeXXX!/spring-petclinic.git"), git CLI will always prompt for password.
When MFA is enabled on GitHub and that you plan to use SSH Keys, you have to use: 
git clone git@github.com:your-git-home/spring-petclinic.git

```sh
eval `ssh-agent -s`
eval $(ssh-agent -s) 
sudo service ssh status
# sudo service ssh --full-restart
ssh-add /home/~username/.ssh/githubkey
ssh-keygen -l -E MD5 -f /home/~username/.ssh/githubkey
ssh -T git@github.com
```

## How to install AZ CLI with Chocolatey
```sh
# https://chocolatey.org/packages/azure-cli
# do not install 2.2.0 as this is a requirement for AAD Integration : az ad app permission admin-consent
# requires version min of 2.0.67 and max of 2.1.0.
# AKS managed-identity requires Azure CLI, version 2.2.0 or later : https://docs.microsoft.com/en-us/azure/aks/use-managed-identity
choco install azure-cli --Yes --confirm --accept-license --version 2.5.1 
```

## How to install Terraform with Chocolatey
```sh
choco install terraform --Yes --confirm --accept-license
choco upgrade terraform --Yes --confirm --accept-license
```

## How to install Terraform on Ubuntu or WSL
[see this blog](https://techcommunity.microsoft.com/t5/azure-developer-community-blog/configuring-terraform-on-windows-10-linux-sub-system/ba-p/393845)
[https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/azure-get-started](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/azure-get-started)
```sh
TF_VER=0.15.5
echo "Installing TF version " $TF_VER
sudo apt-get install unzip
wget https://releases.hashicorp.com/terraform/$TF_VER/terraform_${TF_VER}_linux_amd64.zip -O terraform.zip;
unzip terraform.zip
sudo mv terraform /usr/local/bin
rm terraform.zip
terraform version

# Naming conventions
See also [See also https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/naming-and-tagging](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/naming-and-tagging)

# Mardown docs

- [https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)
- [https://daringfireball.net/projects/markdown/](https://daringfireball.net/projects/markdown/)
- [https://docs.microsoft.com/en-us/contribute/markdown-reference](https://docs.microsoft.com/en-us/contribute/markdown-reference)

# Azure Cloud Shell

You can use the Azure Cloud Shell accessible at <https://shell.azure.com> once you login with an Azure subscription.
See also [https://azure.microsoft.com/en-us/features/cloud-shell/](https://azure.microsoft.com/en-us/features/cloud-shell/)

**/!\ IMPORTANT** Create a storage account for CloudShell in the Region where you plan to deploy your resources and accordingly.
Ex: run CloudShell in France Central Region if you plan do deploy your resources in France Central Region

**/!\ IMPORTANT** CloudShell session idle TimeOut is 20 minutes, you may find WSL/Powershell ISE more confortale.
[https://feedback.azure.com/forums/598699-azure-cloud-shell/suggestions/32240851-fix-increase-cloudshell-timeout](https://feedback.azure.com/forums/598699-azure-cloud-shell/suggestions/32240851-fix-increase-cloudshell-timeout)

[https://medium.com/@navneet.ts/azure-nugget-give-the-cloud-shell-timeout-a-timeout-c486dc544bc3](https://medium.com/@navneet.ts/azure-nugget-give-the-cloud-shell-timeout-a-timeout-c486dc544bc3)

## Uploading and editing files in Azure Cloud Shell

- You can use `vim <file you want to edit>` in Azure Cloud Shell to open the built-in text editor.
- You can upload files to the Azure Cloud Shell by dragging and dropping them
- You can also do a `curl -o filename.ext https://file-url/filename.ext` to download a file from the internet.

## You can Install [Chocolatey](https://chocolatey.org/install) on Windows
```sh
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

# Logs at C:\ProgramData\chocolatey\logs\chocolatey.log 
# Files cached at C:\Users\%USERNAME%\AppData\Local\Temp\chocolatey
```

## How to install Windows Subsystem for Linux (WSL)

```sh
# https://chocolatey.org/packages/wsl
choco install wsl --Yes --confirm --accept-license --verbose 
choco install wsl-ubuntu-1804 --Yes --confirm --accept-license --verbose

```

## Upgrade to to WSL 2
See [https://docs.microsoft.com/en-us/windows/wsl/install-win10#update-to-wsl-2](https://docs.microsoft.com/en-us/windows/wsl/install-win10#update-to-wsl-2)
Pre-req: Windows 10, updated to version 2004, **Build 19041** or higher.

```sh
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# reboot
wsl --set-default-version 2

# The update from WSL 1 to WSL 2 may take several minutes to complete depending on the size of your targeted distribution. If you are running an older (legacy) installation of WSL 1 from Windows 10 Anniversary Update or Creators Update, you may encounter an update error. Follow these instructions to uninstall and remove any legacy distributions.

wsl --list --verbose
wsl --set-version <distribution name> <versionNumber>

```

## Setup PowerShell in WSL
See :
- [https://docs.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7#ubuntu-1804](https://docs.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7#ubuntu-1804)
- [https://www.saggiehaim.net/powershell/install-powershell-7-on-wsl-and-ubuntu](https://www.saggiehaim.net/powershell/install-powershell-7-on-wsl-and-ubuntu)

https://github.com/PowerShell/PowerShell/blob/master/docs/building/linux.md

```sh
# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb

# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb

# Update the list of products
sudo apt-get update

# Enable the "universe" repositories
sudo add-apt-repository universe

# Install PowerShell
sudo apt-get install -y powershell

# restart WSL
pwsh

Get-PSRepository
Install-Module -Name Az

# Create Folder
# sudo mkdir /usr/share/PowerShell
# Change Working Dir
cd /usr/share/PowerShell

# https://github.com/PowerShell/PowerShell/releases/tag/v6.1.5
# sudo wget https://github.com/PowerShell/PowerShell/releases/download/v7.0.0-rc.2/powershell-7.0.0-rc.2-linux-x64.tar.gz
# sudo wget https://github.com/PowerShell/PowerShell/releases/download/v6.1.5/powershell-6.1.5-linux-alpine-x64.tar.gz
# sudo tar xzvf powershell-6.1.5-linux-alpine-x64.tar.gz
# sudo rm /usr/share/PowerShell/powershell-6.1.5-linux-alpine-x64.tar.gz

cd #HOME
 
# Edit the .profile file
vim .profile # PATH="$PATH:/usr/share/PowerShell"

# restart WSL
pwsh

```


## How to install tools into Subsystem for Linux (WSL)

```sh
sudo apt-get install -y apt-transport-https

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo touch /etc/apt/sources.list.d/kubernetes.list 
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
kubectl api-versions

```

## How to install Git bash for Windows 

```sh
# https://chocolatey.org/packages/git.install
# https://gitforwindows.org/
choco install git.install --Yes --confirm --accept-license

```
### Git Troubleshoot

[https://www.illuminiastudios.com/dev-diaries/ssh-on-windows-subsystem-for-linux](https://www.illuminiastudios.com/dev-diaries/ssh-on-windows-subsystem-for-linux)
[https://help.github.com/en/enterprise/2.20/user/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent](https://help.github.com/en/enterprise/2.20/user/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

Check the fingerprint of you SSH key in GitHub with the SSH Key used by git.

If your GIT repo URL starts with HTTPS (ex: "https://github.com/<!XXXyour-git-homeXXX!/spring-petclinic.git"), git CLI will always prompt for password.
When MFA is enabled on GitHub and that you plan to use SSH Keys, you have to use: 
git clone git@github.com:your-git-home/spring-petclinic.git

```sh
eval `ssh-agent -s`
eval $(ssh-agent -s) 
sudo service ssh status
# sudo service ssh --full-restart
ssh-add /home/~username/.ssh/githubkey
ssh-keygen -l -E MD5 -f /home/~username/.ssh/githubkey
ssh -T git@github.com
```

## How to install AZ CLI with Chocolatey
```sh
# https://chocolatey.org/packages/azure-cli
# do not install 2.2.0 as this is a requirement for AAD Integration : az ad app permission admin-consent
# requires version min of 2.0.67 and max of 2.1.0.
# AKS managed-identity requires Azure CLI, version 2.2.0 or later : https://docs.microsoft.com/en-us/azure/aks/use-managed-identity
choco install azure-cli --Yes --confirm --accept-license --version 2.5.1 
```

## How to install Terraform with Chocolatey
```sh
choco install terraform --Yes --confirm --accept-license
choco upgrade terraform --Yes --confirm --accept-license
```

## How to install Terraform on Ubuntu or WSL
[see this blog](https://techcommunity.microsoft.com/t5/azure-developer-community-blog/configuring-terraform-on-windows-10-linux-sub-system/ba-p/393845)
```sh
sudo apt-get install unzip
wget https://releases.hashicorp.com/terraform/0.14.3/terraform_0.14.3_linux_amd64.zip -O terraform.zip;
unzip terraform.zip
sudo mv terraform /usr/local/bin
rm terraform.zip
terraform version

```

## You can use any tool to run SSH & AZ CLI
```sh

sudo apt-get install -y apt-transport-https
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

##### git bash for windows based on Ubuntu
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get update
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | 
    sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-get update
apt search azure-cli 
apt-cache search azure-cli 
apt list azure-cli -a
sudo apt-get install azure-cli # azure-cli=2.16.0-1~bionic

sudo apt-get update && sudo apt-get install --only-upgrade -y azure-cli
sudo apt-get upgrade azure-cli

az version
az login

```

# Install  AZ Data CLI

See [https://docs.microsoft.com/en-us/sql/azdata/install/deploy-install-azdata-linux-package?view=sql-server-ver15](https://docs.microsoft.com/en-us/sql/azdata/install/deploy-install-azdata-linux-package?view=sql-server-ver15)

```sh
sudo apt-get update
sudo apt-get install -y azdata-cli

azdata
azdata --version

sudo apt-get update && sudo apt-get install --only-upgrade -y azdata-cli
```


## Install the AZ ARO extension
AZ ARO is now included in the az core CLI
see :
- [https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster#install-the-az-aro-extension](https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster#install-the-az-aro-extension)
- [source code](https://github.com/Azure/azure-cli/tree/dev/src/azure-cli/azure/cli/command_modules/aro)
```sh
# az extension add -n aro --index https://az.aroapp.io/stable
# az extension update -n aro --index https://az.aroapp.io/stable
# az provider register -n Microsoft.RedHatOpenShift --wait
az -v

```

## Install Azure Bicep CLI

see :
- [https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)

```sh
az -v
az bicep install
az bicep upgrade
az bicep version
az bicep --help
```


## How to install HELM from RedHat

See [https://docs.openshift.com/aro/4/cli_reference/helm_cli/getting-started-with-helm-on-openshift-container-platform.html](https://docs.openshift.com/aro/4/cli_reference/helm_cli/getting-started-with-helm-on-openshift-container-platform.html)
```sh
# https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest
```

## How to install HELM with Chocolatey
```sh
# https://chocolatey.org/packages/kubernetes-helm
choco install kubernetes-helm --Yes --confirm --accept-license
```
## How to install HELM on Ubuntu or WSL
```sh
# https://helm.sh/docs/intro/install/
# https://git.io/get_helm.sh

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

helm version
```

## Kubectl-Windows-Linux-Shell
```sh
# https://github.com/mohatb/kubectl-wls

```

## To run Docker in WSL
The most important part is dockerd will only run on an elevated console (run as Admin) and cgroup should be always mounted before running the docker daemon.

See also :
- [https://github.com/Microsoft/WSL/issues/2291](https://github.com/Microsoft/WSL/issues/2291)
- [https://www.reddit.com/r/bashonubuntuonwindows/comments/8cvr27/docker_is_running_natively_on_wsl/](https://www.reddit.com/r/bashonubuntuonwindows/comments/8cvr27/docker_is_running_natively_on_wsl/)
- [https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly)


run Docker daemon with parameter --iptables=false
you should set this parameter in the configuration file : sudo vim /etc/docker/daemon.json like this:
{
  "iptables":false
}

```sh

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Download and add Docker's official public PGP key.
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Verify the fingerprint.
sudo apt-key fingerprint 0EBFCD88
sudo apt update
sudo apt upgrade
sudo apt install docker.io
sudo cgroupfs-mount
sudo usermod -aG docker $USER
sudo service docker start

```

## Install GCloud on Linux

See :
- [Google SDK doc](https://cloud.google.com/sdk/docs/downloads-versioned-archives)
- [Google regions-zones](https://cloud.google.com/compute/docs/regions-zones#available)
- [Google Cloud account creation](https://cloud.google.com/free)
```sh
getconf LONG_BIT
cd
wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-298.0.0-linux-x86_64.tar.gz
tar xzf google-cloud-sdk-298.0.0-linux-x86_64.tar.gz
rm google-cloud-sdk-298.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh
. .bashrc

# gcloud components install kubectl
sudo gcloud components update -Y

sudo chown usrXXX:grpXXX /home/$USER/.config/gcloud/config_sentinel
sudo chown usrXXX:grpXXX /home/$USER/.config/gcloud/gce
gcloud help
gcloud version

```
## Install GCloud on windows

See :
- [Google SDK doc](https://cloud.google.com/sdk/docs/downloads-versioned-archives)
- [Google regions-zones](https://cloud.google.com/compute/docs/regions-zones#available)
- [Google Cloud account creation](https://cloud.google.com/free)

```sh
https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-298.0.0-windows-x86_64-bundled-python.zip
.\google-cloud-sdk\install.bat
```

## Kube Tools

```sh
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/

# AKS
source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc 
alias k=kubectl
complete -F __start_kubectl k

# ARO
source <(oc completion bash)
echo "source <(oc completion bash)" >> ~/.bashrc 
complete -F __start_oc oc

# K3S
alias k="sudo k3s kubectl"
source <(k completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(k completion bash)" >> ~/.bashrc 
complete -F __start_kubectl k

alias kn='k config set-context --current --namespace '

export gen="--dry-run=client -o yaml"
# ex: k run nginx --image nginx $gen

# Get K8S resources
alias kp="k get pods -o wide"
alias kd="k get deployment -o wide"
alias ks="k get svc -o wide"
alias kno="k get nodes -o wide"

# Describe K8S resources 
alias kdp="k describe pod"
alias kdd="k describe deployment"
alias kds="k describe service"

```

Optionnaly : If you want to run PowerShell
You can use Backtick ` to escape new Line in ISE

```sh
# If you run kubectl in PowerShell ISE , you can also define aliases :
function k([Parameter(ValueFromRemainingArguments = $true)]$params) { & kubectl $params }
function kubectl([Parameter(ValueFromRemainingArguments = $true)]$params) { Write-Output "> kubectl $(@($params | ForEach-Object {$_}) -join ' ')"; & kubectl.exe $params; }
function k([Parameter(ValueFromRemainingArguments = $true)]$params) { Write-Output "> k $(@($params | ForEach-Object {$_}) -join ' ')"; & kubectl.exe $params; }
```

## VIM tips

See [vim cheatsheet](https://devhints.io/vim)

```sh
# set ts=2 : ts stands for tabstop. It sets the tab width to 2 spaces.
# sts stands for softtabstop. Insert ou delete 2 spaces with tab or back keys.
# sw stands for shiftwidth. Number of spaces used during indentation > or <
# set et : et stands for expandtab. While in insert mode, it replaces tabs by spaces
vi ~/.vimrc
set ts=2 sw=2 et sts=2
. ~/.vimrc
```

## Open Policy Agent tools
Install [VSCode extension](https://marketplace.visualstudio.com/items?itemName=tsandall.opa) for [OPA](https://www.openpolicyagent.org)

## ARO tips

[https://github.com/stuartatmicrosoft/azure-aro](https://github.com/stuartatmicrosoft/azure-aro)

## k9s
K9s provides a terminal UI to interact with your Kubernetes clusters. The aim of this project is to make it easier to navigate, observe and manage your applications in the wild. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with your observed resources.

See [https://github.com/derailed/k9s](https://github.com/derailed/k9s)

```sh
# 
wget https://github.com/derailed/k9s/releases/download/v0.19.2/k9s_Linux_x86_64.tar.gz
gunzip k9s_Linux_x86_64.tar.gz
tar -xvf k9s_Linux_x86_64.tar

export TERM=xterm-256color
export EDITOR=vim

 ./k9s help
./k9s version

# To run K9s in a given namespace
k9s -n mycoolns
# Start K9s in an existing KubeConfig context
k9s --context coolCtx

```

# K8SLens

```sh
# https://k8slens.dev/
```

```

## You can use any tool to run SSH & AZ CLI
```sh

sudo apt-get install -y apt-transport-https
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

##### git bash for windows based on Ubuntu
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get update
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | 
    sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-get update
apt search azure-cli 
apt-cache search azure-cli 
apt list azure-cli -a
sudo apt-get install azure-cli # azure-cli=2.16.0-1~bionic

sudo apt-get update && sudo apt-get install --only-upgrade -y azure-cli
sudo apt-get upgrade azure-cli

az login

```

## Install the AZ ARO extension
see :
- [https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster#install-the-az-aro-extension](https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster#install-the-az-aro-extension)
- [source code](https://github.com/Azure/azure-cli/tree/dev/src/azure-cli/azure/cli/command_modules/aro)
```sh
az extension add -n aro --index https://az.aroapp.io/stable
az extension update -n aro --index https://az.aroapp.io/stable
az provider register -n Microsoft.RedHatOpenShift --wait
az -v

```
## How to install HELM from RedHat

See [https://docs.openshift.com/aro/4/cli_reference/helm_cli/getting-started-with-helm-on-openshift-container-platform.html](https://docs.openshift.com/aro/4/cli_reference/helm_cli/getting-started-with-helm-on-openshift-container-platform.html)
```sh
# https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest
```

## How to install HELM with Chocolatey
```sh
# https://chocolatey.org/packages/kubernetes-helm
choco install kubernetes-helm --Yes --confirm --accept-license
```
## How to install HELM on Ubuntu or WSL
```sh
# https://helm.sh/docs/intro/install/
# https://git.io/get_helm.sh

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

helm version
```

## Kubectl-Windows-Linux-Shell
```sh
# https://github.com/mohatb/kubectl-wls

```

## To run Docker in WSL
The most important part is dockerd will only run on an elevated console (run as Admin) and cgroup should be always mounted before running the docker daemon.

See also :
- [https://github.com/Microsoft/WSL/issues/2291](https://github.com/Microsoft/WSL/issues/2291)
- [https://www.reddit.com/r/bashonubuntuonwindows/comments/8cvr27/docker_is_running_natively_on_wsl/](https://www.reddit.com/r/bashonubuntuonwindows/comments/8cvr27/docker_is_running_natively_on_wsl/)
- [https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly)


run Docker daemon with parameter --iptables=false
you should set this parameter in the configuration file : sudo vim /etc/docker/daemon.json like this:
{
  "iptables":false
}

```sh

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Download and add Docker's official public PGP key.
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Verify the fingerprint.
sudo apt-key fingerprint 0EBFCD88
sudo apt update
sudo apt upgrade
sudo apt install docker.io
sudo cgroupfs-mount
sudo usermod -aG docker $USER
sudo service docker start

```

## Install GCloud on Linux

See :
- [Google SDK doc](https://cloud.google.com/sdk/docs/downloads-versioned-archives)
- [Google regions-zones](https://cloud.google.com/compute/docs/regions-zones#available)
- [Google Cloud account creation](https://cloud.google.com/free)
```sh
getconf LONG_BIT
cd
wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-298.0.0-linux-x86_64.tar.gz
tar xzf google-cloud-sdk-298.0.0-linux-x86_64.tar.gz
rm google-cloud-sdk-298.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh
. .bashrc

# gcloud components install kubectl
gcloud components update

sudo chown usrXXX:grpXXX /home/$USER/.config/gcloud/config_sentinel
sudo chown usrXXX:grpXXX /home/$USER/.config/gcloud/gce
gcloud help

```
## Install GCloud on windows

See :
- [Google SDK doc](https://cloud.google.com/sdk/docs/downloads-versioned-archives)
- [Google regions-zones](https://cloud.google.com/compute/docs/regions-zones#available)
- [Google Cloud account creation](https://cloud.google.com/free)

```sh
https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-298.0.0-windows-x86_64-bundled-python.zip
.\google-cloud-sdk\install.bat
```

## Install AWS CLI on Linux

See :
- [AWS SDK doc](https://docs.aws.amazon.com/cdk/api/latest/python/aws_cdk.aws_eks.html)
- [AWS CLI install doc](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [AWS regions-zones](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)
- [Getting started with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
- [Configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
- [AWS Free account creation](https://aws.amazon.com/free)
```sh
# sudo apt install awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

which aws
ls -l /usr/local/bin/aws
aws --version

# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds
aws configure
export AWS_ACCESS_KEY_ID="an access key"
export AWS_SECRET_ACCESS_KEY="a secret key"
export AWS_DEFAULT_REGION="us-west-2"

# Installing or upgrading eksctl: https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# Install AWS IAM Authenticator : https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator
curl -o aws-iam-authenticator.sha256 https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator.sha256
openssl sha1 -sha256 aws-iam-authenticator

chmod +x ./aws-iam-authenticator
mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
aws-iam-authenticator help
aws-iam-authenticator version

```

## Install AWS CLI on Windows
```sh
# msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
# with chocolatey
choco install awscli --Yes --accept-license
```

## Kube Tools

```sh
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/

# AKS
source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc 
alias k=kubectl
complete -F __start_kubectl k

# ARO
source <(oc completion bash)
echo "source <(oc completion bash)" >> ~/.bashrc 
complete -F __start_oc oc

# K3S
alias k="sudo k3s kubectl"
source <(k completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(k completion bash)" >> ~/.bashrc 
complete -F __start_kubectl k

alias kn='k config set-context --current --namespace '

export gen="--dry-run=client -o yaml"
# ex: k run nginx --image nginx $gen

# Get K8S resources
alias kp="k get pods -o wide"
alias kd="k get deployment -o wide"
alias ks="k get svc -o wide"
alias kno="k get nodes -o wide"

# Describe K8S resources 
alias kdp="k describe pod"
alias kdd="k describe deployment"
alias kds="k describe service"

```

## Containerd Tools

See :
- [https://docs.microsoft.com/en-us/azure/aks/cluster-configuration#containerd-limitationsdifferences](https://docs.microsoft.com/en-us/azure/aks/cluster-configuration#containerd-limitationsdifferences)
- [https://github.com/kubernetes-sigs/cri-tools](https://github.com/kubernetes-sigs/cri-tools#install-crictl)

```sh
CRICTL_VERSION="v1.20.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$CRICTL_VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$CRICTL_VERSION-linux-amd64.tar.gz
```

Optionnaly : If you want to run PowerShell
You can use Backtick ` to escape new Line in ISE

```sh
# If you run kubectl in PowerShell ISE , you can also define aliases :
function k([Parameter(ValueFromRemainingArguments = $true)]$params) { & kubectl $params }
function kubectl([Parameter(ValueFromRemainingArguments = $true)]$params) { Write-Output "> kubectl $(@($params | ForEach-Object {$_}) -join ' ')"; & kubectl.exe $params; }
function k([Parameter(ValueFromRemainingArguments = $true)]$params) { Write-Output "> k $(@($params | ForEach-Object {$_}) -join ' ')"; & kubectl.exe $params; }
```

## VIM tips

See [vim cheatsheet](https://devhints.io/vim)

```sh
# set ts=2 : ts stands for tabstop. It sets the tab width to 2 spaces.
# sts stands for softtabstop. Insert ou delete 2 spaces with tab or back keys.
# sw stands for shiftwidth. Number of spaces used during indentation > or <
# set et : et stands for expandtab. While in insert mode, it replaces tabs by spaces
vi ~/.vimrc
set ts=2 sw=2 et sts=2
. ~/.vimrc
```

## Open Policy Agent tools
Install [VSCode extension](https://marketplace.visualstudio.com/items?itemName=tsandall.opa) for [OPA](https://www.openpolicyagent.org)

## ARO tips

[https://github.com/stuartatmicrosoft/azure-aro](https://github.com/stuartatmicrosoft/azure-aro)

## k9s
K9s provides a terminal UI to interact with your Kubernetes clusters. The aim of this project is to make it easier to navigate, observe and manage your applications in the wild. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with your observed resources.

See [https://github.com/derailed/k9s](https://github.com/derailed/k9s)

```sh
# 
wget https://github.com/derailed/k9s/releases/download/v0.19.2/k9s_Linux_x86_64.tar.gz
gunzip k9s_Linux_x86_64.tar.gz
tar -xvf k9s_Linux_x86_64.tar

export TERM=xterm-256color
export EDITOR=vim

 ./k9s help
./k9s version

# To run K9s in a given namespace
k9s -n mycoolns
# Start K9s in an existing KubeConfig context
k9s --context coolCtx

```

# K8SLens

```sh
# https://k8slens.dev/
```