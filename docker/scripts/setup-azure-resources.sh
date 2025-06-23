#!/bin/bash
set -e

# Setup Azure resources for Unstract deployment
# Usage: ./setup-azure-resources.sh <environment>

ENVIRONMENT=${1:-staging}
LOCATION="eastus"
TIMESTAMP=$(date +%s)

# Set environment-specific variables
if [ "$ENVIRONMENT" = "production" ]; then
    RESOURCE_GROUP="unstract-prod-rg"
    REGISTRY_NAME="unstract21468"
    KV_NAME="unstract-prod-kv"
    POSTGRES_NAME="unstract-prod-postgres-$TIMESTAMP"
    REDIS_NAME="unstract-prod-redis-$TIMESTAMP"
    STORAGE_NAME="unstract$TIMESTAMP"
    APP_INSIGHTS_NAME="unstract-prod-insights"
else
    RESOURCE_GROUP="unstract-staging-rg"
    REGISTRY_NAME="unstract21468"
    KV_NAME="unstract-staging-kv"
    POSTGRES_NAME="unstract-staging-postgres-$TIMESTAMP"
    REDIS_NAME="unstract-staging-redis-$TIMESTAMP"
    STORAGE_NAME="unstractstg$TIMESTAMP"
    APP_INSIGHTS_NAME="unstract-staging-insights"
fi

echo "Setting up Azure resources for $ENVIRONMENT environment..."

# Create resource group
echo "Creating resource group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --tags Environment=$ENVIRONMENT Project=Unstract

# Create Container Registry (if not exists)
echo "Setting up Container Registry..."
if ! az acr show --name $REGISTRY_NAME &>/dev/null; then
    az acr create \
        --resource-group $RESOURCE_GROUP \
        --name $REGISTRY_NAME \
        --sku Premium \
        --location $LOCATION
    
    # Enable admin user for initial setup
    az acr update \
        --name $REGISTRY_NAME \
        --admin-enabled true
fi

# Create Key Vault
echo "Creating Key Vault..."
az keyvault create \
    --name $KV_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --enable-rbac-authorization false \
    --enabled-for-deployment true \
    --enabled-for-template-deployment true

# Create PostgreSQL Flexible Server
echo "Creating PostgreSQL server..."
POSTGRES_ADMIN_PASSWORD=$(openssl rand -base64 32)

az postgres flexible-server create \
    --resource-group $RESOURCE_GROUP \
    --name $POSTGRES_NAME \
    --location $LOCATION \
    --admin-user unstract_admin \
    --admin-password "$POSTGRES_ADMIN_PASSWORD" \
    --sku-name Standard_D2ds_v4 \
    --storage-size 128 \
    --version 15 \
    --high-availability Disabled \
    --backup-retention 7 \
    --geo-redundant-backup Disabled

# Enable pgvector extension
az postgres flexible-server parameter set \
    --resource-group $RESOURCE_GROUP \
    --server-name $POSTGRES_NAME \
    --name azure.extensions \
    --value vector

# Create databases
az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $POSTGRES_NAME \
    --database-name unstract_db

az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $POSTGRES_NAME \
    --database-name unstract_prompt_db

az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $POSTGRES_NAME \
    --database-name unstract_x2text_db

az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $POSTGRES_NAME \
    --database-name unstract_platform_db

# Configure firewall rules
az postgres flexible-server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --name $POSTGRES_NAME \
    --rule-name AllowAllAzureIPs \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

# Create Redis Cache
echo "Creating Redis Cache..."
az redis create \
    --resource-group $RESOURCE_GROUP \
    --name $REDIS_NAME \
    --location $LOCATION \
    --sku Standard \
    --vm-size c1 \
    --enable-non-ssl-port false

# Create Storage Account (for MinIO replacement)
echo "Creating Storage Account..."
az storage account create \
    --resource-group $RESOURCE_GROUP \
    --name $STORAGE_NAME \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2 \
    --access-tier Hot

# Create storage containers
az storage container create \
    --account-name $STORAGE_NAME \
    --name unstract \
    --public-access off

az storage container create \
    --account-name $STORAGE_NAME \
    --name prompt-studio-data \
    --public-access off

# Create Application Insights
echo "Creating Application Insights..."
az monitor app-insights component create \
    --app $APP_INSIGHTS_NAME \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP \
    --application-type web

# Get connection strings and keys
echo "Retrieving connection strings..."

# PostgreSQL
POSTGRES_HOST=$(az postgres flexible-server show \
    --resource-group $RESOURCE_GROUP \
    --name $POSTGRES_NAME \
    --query fullyQualifiedDomainName -o tsv)

POSTGRES_CONNECTION="postgresql://unstract_admin:$POSTGRES_ADMIN_PASSWORD@$POSTGRES_HOST:5432/unstract_db?sslmode=require"

# Redis
REDIS_KEY=$(az redis list-keys \
    --resource-group $RESOURCE_GROUP \
    --name $REDIS_NAME \
    --query primaryKey -o tsv)

REDIS_HOST=$(az redis show \
    --resource-group $RESOURCE_GROUP \
    --name $REDIS_NAME \
    --query hostName -o tsv)

REDIS_CONNECTION="rediss://:$REDIS_KEY@$REDIS_HOST:6380/0"

# Storage
STORAGE_KEY=$(az storage account keys list \
    --resource-group $RESOURCE_GROUP \
    --account-name $STORAGE_NAME \
    --query "[0].value" -o tsv)

STORAGE_CONNECTION=$(az storage account show-connection-string \
    --resource-group $RESOURCE_GROUP \
    --name $STORAGE_NAME \
    --query connectionString -o tsv)

# Application Insights
APP_INSIGHTS_KEY=$(az monitor app-insights component show \
    --app $APP_INSIGHTS_NAME \
    --resource-group $RESOURCE_GROUP \
    --query instrumentationKey -o tsv)

# Store secrets in Key Vault
echo "Storing secrets in Key Vault..."

az keyvault secret set \
    --vault-name $KV_NAME \
    --name "postgres-connection-string" \
    --value "$POSTGRES_CONNECTION"

az keyvault secret set \
    --vault-name $KV_NAME \
    --name "postgres-admin-password" \
    --value "$POSTGRES_ADMIN_PASSWORD"

az keyvault secret set \
    --vault-name $KV_NAME \
    --name "redis-connection-string" \
    --value "$REDIS_CONNECTION"

az keyvault secret set \
    --vault-name $KV_NAME \
    --name "storage-connection-string" \
    --value "$STORAGE_CONNECTION"

az keyvault secret set \
    --vault-name $KV_NAME \
    --name "storage-account-key" \
    --value "$STORAGE_KEY"

az keyvault secret set \
    --vault-name $KV_NAME \
    --name "app-insights-key" \
    --value "$APP_INSIGHTS_KEY"

# Generate Django secret key
DJANGO_SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

az keyvault secret set \
    --vault-name $KV_NAME \
    --name "django-secret-key" \
    --value "$DJANGO_SECRET_KEY"

# RabbitMQ connection string (for Container Apps)
RABBITMQ_CONNECTION="amqp://guest:guest@rabbitmq:5672/"

az keyvault secret set \
    --vault-name $KV_NAME \
    --name "rabbitmq-connection-string" \
    --value "$RABBITMQ_CONNECTION"

# Create service principal for GitHub Actions
echo "Creating service principal for GitHub Actions..."
SP_NAME="unstract-github-actions-$ENVIRONMENT"

SP_JSON=$(az ad sp create-for-rbac \
    --name $SP_NAME \
    --role contributor \
    --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP \
    --sdk-auth)

CLIENT_ID=$(echo $SP_JSON | jq -r .clientId)
TENANT_ID=$(echo $SP_JSON | jq -r .tenantId)

# Configure federated credentials for OIDC
echo "Configuring OIDC..."
cat > federated-credential.json <<EOF
{
    "name": "unstract-github-deploy-$ENVIRONMENT",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_ORG/unstract:environment:$ENVIRONMENT",
    "audiences": ["api://AzureADTokenExchange"]
}
EOF

az ad app federated-credential create \
    --id $CLIENT_ID \
    --parameters @federated-credential.json

rm federated-credential.json

# Grant Key Vault access to service principal
az keyvault set-policy \
    --name $KV_NAME \
    --spn $CLIENT_ID \
    --secret-permissions get list

# Grant ACR push access to service principal
ACR_ID=$(az acr show --name $REGISTRY_NAME --query id -o tsv)
az role assignment create \
    --assignee $CLIENT_ID \
    --scope $ACR_ID \
    --role AcrPush

# Output summary
echo ""
echo "=========================================="
echo "Azure resources created successfully!"
echo "=========================================="
echo ""
echo "Resource Group: $RESOURCE_GROUP"
echo "Container Registry: $REGISTRY_NAME.azurecr.io"
echo "Key Vault: $KV_NAME"
echo "PostgreSQL: $POSTGRES_NAME"
echo "Redis: $REDIS_NAME"
echo "Storage Account: $STORAGE_NAME"
echo "Application Insights: $APP_INSIGHTS_NAME"
echo ""
echo "GitHub Actions Configuration:"
echo "-----------------------------"
echo "Add these secrets to your GitHub repository:"
echo ""
echo "AZURE_CLIENT_ID: $CLIENT_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $(az account show --query id -o tsv)"
echo ""
echo "Connection strings have been stored in Key Vault: $KV_NAME"
echo ""
echo "Next steps:"
echo "1. Update GitHub secrets with the values above"
echo "2. Update the federated credential subject with your GitHub org/repo"
echo "3. Run the deployment workflow"