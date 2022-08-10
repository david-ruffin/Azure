# Install az-cli and azure module for RHEL 8. Assuming Ansible is already installed
# https://www.devopszones.com/2020/04/how-to-install-azure-cli-in-cent-os-78.html
# https://docs.microsoft.com/en-us/azure/developer/ansible/install-on-linux-vm?tabs=azure-cli
#!/bin/bash

# Update all packages that have available updates.
sudo yum update -y

# Import the Microsoft repository key.
rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Create local azure-cli repository information.
sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

# Install with the yum install command.
yum install azure-cli -y

# Confirm az-cli version
az --version

# Install Python 3 and pip.
sudo yum install -y python3-pip

# Upgrade pip3.
sudo pip3 install --upgrade pip

# Install Ansible.
pip3 install "ansible==2.9.17"

# Install Ansible azure_rm module for interacting with Azure.
pip3 install ansible[azure]

# make azure dir
mkdir ~/.azure

# Create Ansible credentials file.
sh -c 'echo -e "[default]
subscription_id=b0b9cafa-3a92-4797-b19e-eac855d82ba6
client_id=bfccd8cc-a57a-41ad-80da-b89b3cffd776
secret=t7o8Q~tRlcvrESBt56TVe5VaDGCS8eyzKONTYcdc
tenant=5a5b6888-acb2-4d8b-baa6-97a5aa036219" > ~/.azure/credentials'

az-login

#Ansible 2.9 with azure_rm module
ansible localhost -m azure_rm_resourcegroup -a "name=ansible-test location=eastus"
