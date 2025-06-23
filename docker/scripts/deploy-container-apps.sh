#!/bin/bash
set -e

# Deploy Unstract to Azure Container Apps
# Usage: ./deploy-container-apps.sh <environment> <version>

ENVIRONMENT=${1:-staging}
VERSION=${2:-latest}
REGISTRY="acrunstract21468.azurecr.io"

# Environment-specific configurations
if [ "$ENVIRONMENT" = "production" ]; then
    RESOURCE_GROUP="unstract-prod-rg"
    CONTAINER_ENV="unstract-prod-env"
    LOCATION="eastus"
    MIN_REPLICAS=2
    MAX_REPLICAS=20
    CPU_BACKEND="2"
    MEMORY_BACKEND="4Gi"
    DOMAIN_SUFFIX="unstract.example.com"
else
    RESOURCE_GROUP="unstract-staging-rg"
    CONTAINER_ENV="unstract-staging-env"
    LOCATION="eastus"
    MIN_REPLICAS=1
    MAX_REPLICAS=10
    CPU_BACKEND="1"
    MEMORY_BACKEND="2Gi"
    DOMAIN_SUFFIX="staging.unstract.example.com"
fi

echo "Deploying Unstract to $ENVIRONMENT environment..."
echo "Version: $VERSION"
echo "Container Environment: $CONTAINER_ENV"

# Create resource group if it doesn't exist
echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION --output none 2>/dev/null || true

# Create Container Apps environment if it doesn't exist
echo "Creating Container Apps environment..."
az containerapp env create \
    --name $CONTAINER_ENV \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --output none 2>/dev/null || true

# Get Key Vault secrets
echo "Fetching secrets from Key Vault..."
KV_NAME="unstract-${ENVIRONMENT}-kv"

# Function to deploy or update a container app
deploy_app() {
    local APP_NAME=$1
    local IMAGE=$2
    local PORT=$3
    local INGRESS_TYPE=$4
    local CPU=$5
    local MEMORY=$6
    local MIN_REP=$7
    local MAX_REP=$8
    local ENV_VARS=$9
    local COMMAND=${10}
    
    echo "Deploying $APP_NAME..."
    
    # Check if app exists
    if az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
        # Update existing app
        az containerapp update \
            --name $APP_NAME \
            --resource-group $RESOURCE_GROUP \
            --image $IMAGE \
            --cpu $CPU \
            --memory $MEMORY \
            --min-replicas $MIN_REP \
            --max-replicas $MAX_REP \
            --set-env-vars $ENV_VARS \
            --output none
    else
        # Create new app
        local INGRESS_PARAMS=""
        if [ "$INGRESS_TYPE" != "none" ]; then
            INGRESS_PARAMS="--ingress $INGRESS_TYPE --target-port $PORT"
        fi
        
        local COMMAND_PARAMS=""
        if [ -n "$COMMAND" ]; then
            COMMAND_PARAMS="--command $COMMAND"
        fi
        
        az containerapp create \
            --name $APP_NAME \
            --resource-group $RESOURCE_GROUP \
            --environment $CONTAINER_ENV \
            --image $IMAGE \
            --cpu $CPU \
            --memory $MEMORY \
            --min-replicas $MIN_REP \
            --max-replicas $MAX_REP \
            --env-vars $ENV_VARS \
            $INGRESS_PARAMS \
            $COMMAND_PARAMS \
            --output none
    fi
}

# Common environment variables
COMMON_ENV="ENVIRONMENT=$ENVIRONMENT"

# Deploy Backend
deploy_app \
    "unstract-backend-$ENVIRONMENT" \
    "$REGISTRY/unstract/backend:$VERSION" \
    "8000" \
    "internal" \
    "$CPU_BACKEND" \
    "$MEMORY_BACKEND" \
    "$MIN_REPLICAS" \
    "$MAX_REPLICAS" \
    "$COMMON_ENV DJANGO_SETTINGS_MODULE=backend.settings.production APPLICATION_NAME=unstract-backend"

# Deploy Frontend
deploy_app \
    "unstract-frontend-$ENVIRONMENT" \
    "$REGISTRY/unstract/frontend:$VERSION" \
    "80" \
    "external" \
    "0.5" \
    "1Gi" \
    "$MIN_REPLICAS" \
    "5" \
    "$COMMON_ENV APPLICATION_NAME=unstract-frontend"

# Deploy Platform Service
deploy_app \
    "unstract-platform-$ENVIRONMENT" \
    "$REGISTRY/unstract/platform-service:$VERSION" \
    "3001" \
    "internal" \
    "0.5" \
    "1Gi" \
    "1" \
    "3" \
    "$COMMON_ENV APPLICATION_NAME=unstract-platform-service"

# Deploy Prompt Service
deploy_app \
    "unstract-prompt-$ENVIRONMENT" \
    "$REGISTRY/unstract/prompt-service:$VERSION" \
    "3003" \
    "internal" \
    "1" \
    "2Gi" \
    "1" \
    "5" \
    "$COMMON_ENV APPLICATION_NAME=unstract-prompt-service"

# Deploy X2Text Service
deploy_app \
    "unstract-x2text-$ENVIRONMENT" \
    "$REGISTRY/unstract/x2text-service:$VERSION" \
    "3004" \
    "internal" \
    "0.5" \
    "1Gi" \
    "1" \
    "3" \
    "$COMMON_ENV APPLICATION_NAME=unstract-x2text-service"

# Deploy Runner
deploy_app \
    "unstract-runner-$ENVIRONMENT" \
    "$REGISTRY/unstract/runner:$VERSION" \
    "5002" \
    "internal" \
    "1" \
    "2Gi" \
    "1" \
    "5" \
    "$COMMON_ENV APPLICATION_NAME=unstract-runner"

# Deploy Celery Workers with KEDA scaling
echo "Deploying Celery workers..."

# Default Worker
az containerapp create \
    --name "unstract-worker-$ENVIRONMENT" \
    --resource-group $RESOURCE_GROUP \
    --environment $CONTAINER_ENV \
    --image "$REGISTRY/unstract/backend:$VERSION" \
    --cpu "1" \
    --memory "2Gi" \
    --min-replicas 0 \
    --max-replicas 10 \
    --env-vars "$COMMON_ENV APPLICATION_NAME=unstract-worker" \
    --command ".venv/bin/celery" \
    --args "-A" "backend" "worker" "--loglevel=info" "-Q" "celery,celery_api_deployments" \
    --scale-rule-name "rabbitmq-queue" \
    --scale-rule-type "rabbitmq" \
    --scale-rule-metadata "queueName=celery" "queueLength=5" \
    --scale-rule-auth "connection=rabbitmq-connection-string" \
    --secrets "rabbitmq-connection-string=keyvaultref:$KV_NAME/rabbitmq-connection-string" \
    --output none 2>/dev/null || \
az containerapp update \
    --name "unstract-worker-$ENVIRONMENT" \
    --resource-group $RESOURCE_GROUP \
    --image "$REGISTRY/unstract/backend:$VERSION" \
    --output none

# File Processing Worker
az containerapp create \
    --name "unstract-worker-file-$ENVIRONMENT" \
    --resource-group $RESOURCE_GROUP \
    --environment $CONTAINER_ENV \
    --image "$REGISTRY/unstract/backend:$VERSION" \
    --cpu "1" \
    --memory "2Gi" \
    --min-replicas 0 \
    --max-replicas 20 \
    --env-vars "$COMMON_ENV APPLICATION_NAME=unstract-worker-file-processing" \
    --command ".venv/bin/celery" \
    --args "-A" "backend.workers.file_processing" "worker" "--loglevel=info" "-Q" "file_processing,api_file_processing" \
    --scale-rule-name "rabbitmq-queue" \
    --scale-rule-type "rabbitmq" \
    --scale-rule-metadata "queueName=file_processing" "queueLength=2" \
    --scale-rule-auth "connection=rabbitmq-connection-string" \
    --secrets "rabbitmq-connection-string=keyvaultref:$KV_NAME/rabbitmq-connection-string" \
    --output none 2>/dev/null || \
az containerapp update \
    --name "unstract-worker-file-$ENVIRONMENT" \
    --resource-group $RESOURCE_GROUP \
    --image "$REGISTRY/unstract/backend:$VERSION" \
    --output none

# Celery Beat (always one instance)
deploy_app \
    "unstract-beat-$ENVIRONMENT" \
    "$REGISTRY/unstract/backend:$VERSION" \
    "0" \
    "none" \
    "0.25" \
    "0.5Gi" \
    "1" \
    "1" \
    "$COMMON_ENV APPLICATION_NAME=unstract-celery-beat" \
    '".venv/bin/celery" "-A" "backend" "beat" "--scheduler" "django_celery_beat.schedulers:DatabaseScheduler"'

# Configure custom domain and SSL
echo "Configuring custom domain..."
az containerapp hostname add \
    --name "unstract-frontend-$ENVIRONMENT" \
    --resource-group $RESOURCE_GROUP \
    --hostname "$DOMAIN_SUFFIX" \
    --output none 2>/dev/null || true

# Create ingress rules for internal services
echo "Configuring service discovery..."

# Get frontend URL
FRONTEND_URL=$(az containerapp show \
    --name "unstract-frontend-$ENVIRONMENT" \
    --resource-group $RESOURCE_GROUP \
    --query "properties.configuration.ingress.fqdn" \
    -o tsv)

echo ""
echo "Deployment completed!"
echo "Frontend URL: https://$FRONTEND_URL"
echo ""
echo "To view logs:"
echo "az containerapp logs show --name unstract-backend-$ENVIRONMENT --resource-group $RESOURCE_GROUP --follow"