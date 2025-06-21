#!/bin/bash

# Quick ACR Deployment Script - Pull pre-built images and push to ACR
# This script uses Docker Hub images instead of building locally

set -e

# Configuration
ACR_NAME="acrunstract21468"
ACR_LOGIN_SERVER="acrunstract21468.azurecr.io"
VERSION="${VERSION:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Images to process
declare -a ALL_IMAGES=(
    "unstract/backend:${VERSION}"
    "unstract/frontend:${VERSION}"
    "unstract/platform-service:${VERSION}"
    "unstract/prompt-service:${VERSION}"
    "unstract/x2text-service:${VERSION}"
    "unstract/runner:${VERSION}"
    "postgres:16-alpine"
    "redis:7.2-alpine"
    "rabbitmq:3.13-management-alpine"
    "minio/minio:latest"
    "minio/mc:latest"
    "traefik:3.0"
)

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Main process
print_message $BLUE "Starting Quick ACR Deployment..."

# Login to ACR
print_message $YELLOW "Logging in to ACR..."
az acr login --name ${ACR_NAME}

# Process each image
for image in "${ALL_IMAGES[@]}"; do
    print_message $BLUE "Processing ${image}..."
    
    # Pull image
    print_message $YELLOW "  Pulling ${image}..."
    docker pull "${image}" || {
        print_message $RED "  Failed to pull ${image}"
        continue
    }
    
    # Tag for ACR
    acr_image="${ACR_LOGIN_SERVER}/${image}"
    print_message $YELLOW "  Tagging as ${acr_image}..."
    docker tag "${image}" "${acr_image}"
    
    # Push to ACR
    print_message $YELLOW "  Pushing to ACR..."
    docker push "${acr_image}" || {
        print_message $RED "  Failed to push ${acr_image}"
        continue
    }
    
    print_message $GREEN "  ✓ ${image} processed successfully"
done

# Show ACR status
print_message $BLUE "\n=== ACR Repository Status ==="
az acr repository list --name ${ACR_NAME} --output table

# Create deployment compose file
print_message $BLUE "\nCreating ACR deployment compose file..."
cat > /Users/jerrymorgan/Downloads/unstract-0.123.2/docker/docker-compose.acr.yaml << 'EOF'
# ACR Override for Unstract
version: '3.8'

services:
  backend:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:${VERSION:-latest}
  
  worker:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:${VERSION:-latest}
  
  worker-logging:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:${VERSION:-latest}
  
  worker-file-processing:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:${VERSION:-latest}
  
  worker-file-processing-callback:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:${VERSION:-latest}
  
  celery-flower:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:${VERSION:-latest}
  
  celery-beat:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:${VERSION:-latest}
  
  frontend:
    image: ${ACR_LOGIN_SERVER}/unstract/frontend:${VERSION:-latest}
  
  platform-service:
    image: ${ACR_LOGIN_SERVER}/unstract/platform-service:${VERSION:-latest}
  
  prompt-service:
    image: ${ACR_LOGIN_SERVER}/unstract/prompt-service:${VERSION:-latest}
  
  x2text-service:
    image: ${ACR_LOGIN_SERVER}/unstract/x2text-service:${VERSION:-latest}
  
  runner:
    image: ${ACR_LOGIN_SERVER}/unstract/runner:${VERSION:-latest}
  
  db:
    image: ${ACR_LOGIN_SERVER}/postgres:16-alpine
  
  redis:
    image: ${ACR_LOGIN_SERVER}/redis:7.2-alpine
  
  rabbitmq:
    image: ${ACR_LOGIN_SERVER}/rabbitmq:3.13-management-alpine
  
  minio:
    image: ${ACR_LOGIN_SERVER}/minio/minio:latest
  
  createbuckets:
    image: ${ACR_LOGIN_SERVER}/minio/mc:latest
  
  reverse-proxy:
    image: ${ACR_LOGIN_SERVER}/traefik:3.0
EOF

# Update the compose file with actual ACR server
sed -i.bak "s/\${ACR_LOGIN_SERVER}/${ACR_LOGIN_SERVER}/g" /Users/jerrymorgan/Downloads/unstract-0.123.2/docker/docker-compose.acr.yaml

print_message $GREEN "\n=== Deployment Complete! ==="
print_message $YELLOW "To deploy using ACR images:"
echo "  cd docker"
echo "  export ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}"
echo "  docker-compose -f docker-compose.yaml -f docker-compose.acr.yaml up -d"

# Check for vulnerabilities
print_message $BLUE "\n=== Checking for vulnerabilities ==="
for repo in unstract/backend unstract/frontend unstract/platform-service unstract/prompt-service unstract/x2text-service unstract/runner; do
    print_message $YELLOW "Scanning ${repo}..."
    az acr repository show --name ${ACR_NAME} --repository "${repo}" --output table || true
done