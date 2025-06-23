#!/bin/bash
set -e

# Configuration
RESOURCE_GROUP="unstract-rg"
LOCATION="eastus"
AKS_NAME="unstract-aks"
ACR_NAME="unstractacr"
AKS_NODE_COUNT=2
AKS_NODE_VM_SIZE="Standard_D4s_v3"
POSTGRES_NAME="unstract-postgres"
REDIS_NAME="unstract-redis"
STORAGE_ACCOUNT="unstractstorage"
KEY_VAULT_NAME="unstract-kv"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it first: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Login to Azure
echo "Logging in to Azure..."
az login --use-device-code

# Set subscription (uncomment and modify if needed)
# echo "Setting subscription..."
# az account set --subscription "your-subscription-id"

# Create resource group
echo "Creating resource group '$RESOURCE_GROUP'..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry (ACR)
echo "Creating Azure Container Registry '$ACR_NAME'..."
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Standard --admin-enabled true

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
echo "ACR Login Server: $ACR_LOGIN_SERVER"

# Create AKS cluster with managed identity
echo "Creating AKS cluster '$AKS_NAME'..."
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --node-count $AKS_NODE_COUNT \
    --node-vm-size $AKS_NODE_VM_SIZE \
    --generate-ssh-keys \
    --enable-managed-identity \
    --attach-acr $ACR_NAME \
    --enable-addons monitoring \
    --network-plugin azure \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 5

# Get AKS credentials
echo "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

# Create Azure Database for PostgreSQL
echo "Creating Azure Database for PostgreSQL '$POSTGRES_NAME'..."
az postgres flexible-server create \
    --resource-group $RESOURCE_GROUP \
    --name $POSTGRES_NAME \
    --location $LOCATION \
    --admin-user unstractadmin \
    --admin-password "$(openssl rand -base64 16)" \
    --sku-name Standard_D4s_v3 \
    --tier GeneralPurpose \
    --version 14 \
    --storage-size 32768 \
    --yes

# Create Azure Cache for Redis
echo "Creating Azure Cache for Redis '$REDIS_NAME'..."
az redis create \
    --resource-group $RESOURCE_GROUP \
    --name $REDIS_NAME \
    --location $LOCATION \
    --sku Standard \
    --vm-size c1

# Create Storage Account
echo "Creating Storage Account '$STORAGE_ACCOUNT'..."
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS

# Create Key Vault
echo "Creating Key Vault '$KEY_VAULT_NAME'..."
az keyvault create \
    --name $KEY_VAULT_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --enabled-for-deployment true \
    --enabled-for-disk-encryption true \
    --enabled-for-template-deployment true

# Output resource information
echo "\n=== Azure Resources Created Successfully ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "AKS Cluster: $AKS_NAME"
echo "ACR: $ACR_NAME"
echo "PostgreSQL: $POSTGRES_NAME"
echo "Redis: $REDIS_NAME"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Key Vault: $KEY_VAULT_NAME"
echo "\nNext steps:"
echo "1. Run 'az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME' to configure kubectl"
echo "2. Run 'az acr login --name $ACR_NAME' to log in to the container registry"
echo "3. Deploy your application using the provided Kubernetes manifests"
