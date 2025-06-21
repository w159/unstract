#!/bin/bash
# Deploy Unstract to Azure Kubernetes Service

set -e

# Configuration
ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
NAMESPACE="unstract-${ENVIRONMENT}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed"
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed"
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Run 'az login' first"
        exit 1
    fi
}

# Get AKS credentials
get_aks_credentials() {
    print_status "Getting AKS credentials..."
    
    RESOURCE_GROUP="rg-unstract-${ENVIRONMENT}"
    CLUSTER_NAME="aks-unstract-${ENVIRONMENT}"
    
    az aks get-credentials \
        --resource-group "$RESOURCE_GROUP" \
        --name "$CLUSTER_NAME" \
        --overwrite-existing
}

# Create namespace
create_namespace() {
    print_status "Creating namespace ${NAMESPACE}..."
    
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
}

# Sync secrets from Key Vault
sync_keyvault_secrets() {
    print_status "Syncing secrets from Key Vault..."
    
    KEY_VAULT_NAME="kv-unstract-${ENVIRONMENT}"
    
    # Get secrets from Key Vault
    DB_HOST=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "db-host" --query value -o tsv)
    DB_NAME=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "db-name" --query value -o tsv)
    DB_USER=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "db-user" --query value -o tsv)
    DB_PASSWORD=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "db-password" --query value -o tsv)
    REDIS_HOST=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "redis-host" --query value -o tsv)
    REDIS_PASSWORD=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "redis-password" --query value -o tsv)
    STORAGE_CONNECTION_STRING=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "storage-connection-string" --query value -o tsv)
    SERVICEBUS_CONNECTION_STRING=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "servicebus-connection-string" --query value -o tsv)
    ENCRYPTION_KEY=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "encryption-key" --query value -o tsv)
    
    # Create Kubernetes secret
    kubectl create secret generic unstract-secrets \
        --from-literal=db-host="$DB_HOST" \
        --from-literal=db-name="$DB_NAME" \
        --from-literal=db-user="$DB_USER" \
        --from-literal=db-password="$DB_PASSWORD" \
        --from-literal=redis-host="$REDIS_HOST" \
        --from-literal=redis-password="$REDIS_PASSWORD" \
        --from-literal=storage-connection-string="$STORAGE_CONNECTION_STRING" \
        --from-literal=servicebus-connection-string="$SERVICEBUS_CONNECTION_STRING" \
        --from-literal=encryption-key="$ENCRYPTION_KEY" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Create ACR pull secret
create_acr_secret() {
    print_status "Creating ACR pull secret..."
    
    ACR_NAME="acrunstract${ENVIRONMENT}"
    ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
    ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
    ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value -o tsv)
    
    kubectl create secret docker-registry acr-secret \
        --docker-server="$ACR_LOGIN_SERVER" \
        --docker-username="$ACR_USERNAME" \
        --docker-password="$ACR_PASSWORD" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Deploy ConfigMap
deploy_configmap() {
    print_status "Deploying ConfigMap..."
    
    kubectl create configmap unstract-config \
        --from-env-file="./k8s/environments/${ENVIRONMENT}/config.env" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Deploy persistent volumes
deploy_storage() {
    print_status "Deploying persistent volume claims..."
    
    kubectl apply -f ./k8s/manifests/base/storage.yaml -n "$NAMESPACE"
}

# Deploy applications
deploy_applications() {
    print_status "Deploying Unstract applications..."
    
    # Get ACR login server
    ACR_NAME="acrunstract${ENVIRONMENT}"
    ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
    
    # Update image tags in manifests
    find ./k8s/manifests -name "*.yaml" -type f -exec \
        sed -i.bak \
        -e "s|IMAGE_TAG|${IMAGE_TAG}|g" \
        -e "s|\${ACR_LOGIN_SERVER}|${ACR_LOGIN_SERVER}|g" {} \;
    
    # Apply base manifests
    kubectl apply -f ./k8s/manifests/base/ -n "$NAMESPACE"
    
    # Apply environment-specific manifests
    if [ -d "./k8s/manifests/${ENVIRONMENT}" ]; then
        kubectl apply -f "./k8s/manifests/${ENVIRONMENT}/" -n "$NAMESPACE"
    fi
    
    # Restore original files
    find ./k8s/manifests -name "*.yaml.bak" -type f -exec rm {} \;
}

# Install ingress controller
install_ingress() {
    print_status "Installing NGINX ingress controller..."
    
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
}

# Wait for deployments
wait_for_deployments() {
    print_status "Waiting for deployments to be ready..."
    
    kubectl wait --for=condition=available --timeout=600s \
        deployment/backend \
        deployment/frontend \
        deployment/platform-service \
        deployment/prompt-service \
        deployment/runner \
        deployment/x2text-service \
        -n "$NAMESPACE"
}

# Run database migrations
run_migrations() {
    print_status "Running database migrations..."
    
    POD=$(kubectl get pod -n "$NAMESPACE" -l component=backend -o jsonpath="{.items[0].metadata.name}")
    kubectl exec -it "$POD" -n "$NAMESPACE" -- python manage.py migrate --no-input
}

# Get ingress IP
get_ingress_ip() {
    print_status "Getting ingress IP address..."
    
    INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    echo
    echo "========================================="
    echo "Deployment Complete!"
    echo "========================================="
    echo
    echo "Ingress IP: $INGRESS_IP"
    echo "Frontend URL: http://$INGRESS_IP"
    echo "Backend API: http://$INGRESS_IP/api/v1"
    echo
    echo "To check deployment status:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo
    echo "To view logs:"
    echo "  kubectl logs -n $NAMESPACE -l component=backend"
    echo
}

# Main deployment flow
main() {
    echo "=== Deploying Unstract to AKS ==="
    echo "Environment: $ENVIRONMENT"
    echo "Image Tag: $IMAGE_TAG"
    echo
    
    check_prerequisites
    get_aks_credentials
    create_namespace
    sync_keyvault_secrets
    create_acr_secret
    deploy_configmap
    deploy_storage
    deploy_applications
    install_ingress
    wait_for_deployments
    run_migrations
    get_ingress_ip
}

# Run main function
main "$@"