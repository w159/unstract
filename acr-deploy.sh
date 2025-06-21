#!/bin/bash

# ACR Deployment Script for Unstract
# This script pulls, tags, and pushes all Unstract images to Azure Container Registry

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
declare -a UNSTRACT_IMAGES=(
    "unstract/backend"
    "unstract/frontend"
    "unstract/platform-service"
    "unstract/prompt-service"
    "unstract/x2text-service"
    "unstract/runner"
)

declare -a ESSENTIAL_IMAGES=(
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

# Function to build images locally
build_images() {
    print_message $BLUE "=== Building Unstract images locally ==="
    
    cd /Users/jerrymorgan/Downloads/unstract-0.123.2
    
    # Build backend image
    print_message $YELLOW "Building backend image..."
    docker build -f docker/dockerfiles/backend.Dockerfile -t unstract/backend:${VERSION} . || {
        print_message $RED "Failed to build backend image"
        exit 1
    }
    
    # Build frontend image
    print_message $YELLOW "Building frontend image..."
    docker build -f docker/dockerfiles/frontend.Dockerfile -t unstract/frontend:${VERSION} . || {
        print_message $RED "Failed to build frontend image"
        exit 1
    }
    
    # Build platform-service image
    print_message $YELLOW "Building platform-service image..."
    docker build -f docker/dockerfiles/platform.Dockerfile -t unstract/platform-service:${VERSION} . || {
        print_message $RED "Failed to build platform-service image"
        exit 1
    }
    
    # Build prompt-service image
    print_message $YELLOW "Building prompt-service image..."
    docker build -f docker/dockerfiles/prompt.Dockerfile -t unstract/prompt-service:${VERSION} . || {
        print_message $RED "Failed to build prompt-service image"
        exit 1
    }
    
    # Build x2text-service image
    print_message $YELLOW "Building x2text-service image..."
    docker build -f docker/dockerfiles/x2text.Dockerfile -t unstract/x2text-service:${VERSION} . || {
        print_message $RED "Failed to build x2text-service image"
        exit 1
    }
    
    # Build runner image
    print_message $YELLOW "Building runner image..."
    docker build -f docker/dockerfiles/runner.Dockerfile -t unstract/runner:${VERSION} . || {
        print_message $RED "Failed to build runner image"
        exit 1
    }
    
    print_message $GREEN "All images built successfully!"
}

# Function to pull images
pull_images() {
    print_message $BLUE "=== Pulling essential service images ==="
    
    # Only pull essential service images (not Unstract images since we're building them)
    for image in "${ESSENTIAL_IMAGES[@]}"; do
        print_message $YELLOW "Pulling ${image}..."
        docker pull "${image}" || {
            print_message $RED "Failed to pull ${image}"
            exit 1
        }
    done
    
    print_message $GREEN "Essential images pulled successfully!"
}

# Function to tag images for ACR
tag_images() {
    print_message $BLUE "=== Tagging images for ACR ==="
    
    # Tag Unstract images
    for image in "${UNSTRACT_IMAGES[@]}"; do
        local source="${image}:${VERSION}"
        local target="${ACR_LOGIN_SERVER}/${image}:${VERSION}"
        print_message $YELLOW "Tagging ${source} -> ${target}..."
        docker tag "${source}" "${target}"
    done
    
    # Tag essential service images
    for image in "${ESSENTIAL_IMAGES[@]}"; do
        local target="${ACR_LOGIN_SERVER}/${image}"
        print_message $YELLOW "Tagging ${image} -> ${target}..."
        docker tag "${image}" "${target}"
    done
    
    print_message $GREEN "All images tagged successfully!"
}

# Function to push images to ACR
push_images() {
    print_message $BLUE "=== Pushing images to ACR ==="
    
    # Push Unstract images
    for image in "${UNSTRACT_IMAGES[@]}"; do
        local target="${ACR_LOGIN_SERVER}/${image}:${VERSION}"
        print_message $YELLOW "Pushing ${target}..."
        docker push "${target}" || {
            print_message $RED "Failed to push ${target}"
            exit 1
        }
    done
    
    # Push essential service images
    for image in "${ESSENTIAL_IMAGES[@]}"; do
        local target="${ACR_LOGIN_SERVER}/${image}"
        print_message $YELLOW "Pushing ${target}..."
        docker push "${target}" || {
            print_message $RED "Failed to push ${target}"
            exit 1
        }
    done
    
    print_message $GREEN "All images pushed successfully!"
}

# Function to scan images in ACR
scan_acr_images() {
    print_message $BLUE "=== Scanning ACR images for vulnerabilities ==="
    
    # List all repositories
    print_message $YELLOW "Listing all repositories in ACR..."
    az acr repository list --name ${ACR_NAME} --output table
    
    # Show vulnerabilities for Unstract images
    for image in "${UNSTRACT_IMAGES[@]}"; do
        print_message $YELLOW "Checking vulnerabilities for ${image}..."
        az acr repository show --name ${ACR_NAME} --repository "${image}" --output table || true
    done
}

# Function to check ACR health
check_acr_health() {
    print_message $BLUE "=== Checking ACR Health ==="
    
    # Check ACR status
    print_message $YELLOW "ACR Details:"
    az acr show --name ${ACR_NAME} --output table
    
    # Check storage usage
    print_message $YELLOW "Storage Usage:"
    az acr show-usage --name ${ACR_NAME} --output table
}

# Function to update docker-compose for ACR
update_compose_for_acr() {
    print_message $BLUE "=== Creating ACR-specific docker-compose override ==="
    
    cat > /Users/jerrymorgan/Downloads/unstract-0.123.2/docker/docker-compose.acr.yaml << EOF
# ACR Override for Unstract
# This file overrides image references to use ACR

version: '3.8'

services:
  backend:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:\${VERSION:-latest}
  
  worker:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:\${VERSION:-latest}
  
  worker-logging:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:\${VERSION:-latest}
  
  worker-file-processing:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:\${VERSION:-latest}
  
  worker-file-processing-callback:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:\${VERSION:-latest}
  
  celery-flower:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:\${VERSION:-latest}
  
  celery-beat:
    image: ${ACR_LOGIN_SERVER}/unstract/backend:\${VERSION:-latest}
  
  frontend:
    image: ${ACR_LOGIN_SERVER}/unstract/frontend:\${VERSION:-latest}
  
  platform-service:
    image: ${ACR_LOGIN_SERVER}/unstract/platform-service:\${VERSION:-latest}
  
  prompt-service:
    image: ${ACR_LOGIN_SERVER}/unstract/prompt-service:\${VERSION:-latest}
  
  x2text-service:
    image: ${ACR_LOGIN_SERVER}/unstract/x2text-service:\${VERSION:-latest}
  
  runner:
    image: ${ACR_LOGIN_SERVER}/unstract/runner:\${VERSION:-latest}
  
  # Essential services
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
    
    print_message $GREEN "Created docker-compose.acr.yaml"
}

# Main execution
main() {
    print_message $BLUE "Starting ACR deployment process..."
    
    # Login to ACR
    print_message $YELLOW "Logging in to ACR..."
    az acr login --name ${ACR_NAME}
    
    # Execute all steps
    pull_images
    build_images
    tag_images
    push_images
    scan_acr_images
    check_acr_health
    update_compose_for_acr
    
    print_message $GREEN "=== ACR deployment completed successfully! ==="
    print_message $YELLOW "To deploy using ACR images, use:"
    echo "  docker-compose -f docker/docker-compose.yaml -f docker/docker-compose.acr.yaml up -d"
}

# Run main
main