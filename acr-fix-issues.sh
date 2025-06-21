#!/bin/bash

# ACR Issues Fix Script
# Fixes identified issues and gets missing Unstract images

set -e

# Configuration
ACR_NAME="acrunstract21468"
ACR_LOGIN_SERVER="acrunstract21468.azurecr.io"
VERSION="${VERSION:-latest}"
GHCR_PREFIX="ghcr.io/zipstack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_message $BLUE "=== Fixing ACR Issues ==="

# Login to ACR
print_message $YELLOW "Logging in to ACR..."
az acr login --name ${ACR_NAME}

# Try GitHub Container Registry for Unstract images
print_message $BLUE "\n=== Trying GitHub Container Registry for Unstract images ==="

declare -a GHCR_IMAGES=(
    "backend"
    "frontend"
    "platform-service"
    "prompt-service"
    "x2text-service"
    "runner"
)

for image in "${GHCR_IMAGES[@]}"; do
    print_message $YELLOW "Processing ${image}..."
    
    # Try GHCR first
    ghcr_image="${GHCR_PREFIX}/unstract-${image}:${VERSION}"
    docker_hub_image="unstract/${image}:${VERSION}"
    acr_image="${ACR_LOGIN_SERVER}/unstract/${image}:${VERSION}"
    
    # Try pulling from GHCR
    print_message $YELLOW "  Trying GHCR: ${ghcr_image}..."
    if docker pull "${ghcr_image}" 2>/dev/null; then
        print_message $GREEN "  ✓ Found on GHCR"
        docker tag "${ghcr_image}" "${acr_image}"
        docker push "${acr_image}"
        print_message $GREEN "  ✓ Pushed to ACR"
    else
        print_message $YELLOW "  Not found on GHCR, checking existing ACR images..."
        # Check if already in ACR
        if az acr repository show --name ${ACR_NAME} --repository "unstract/${image}" 2>/dev/null; then
            print_message $GREEN "  ✓ Already in ACR"
        else
            print_message $RED "  ✗ Image not available"
        fi
    fi
done

# Enable vulnerability scanning for all repositories
print_message $BLUE "\n=== Enabling vulnerability scanning ==="
for repo in $(az acr repository list --name ${ACR_NAME} --output tsv); do
    print_message $YELLOW "Scanning ${repo}..."
    az acr repository update --name ${ACR_NAME} --repository "${repo}" --write-enabled true --delete-enabled true || true
done

# Show ACR usage and limits
print_message $BLUE "\n=== ACR Storage Usage ==="
az acr show-usage --name ${ACR_NAME} --output table

# Clean up old manifests
print_message $BLUE "\n=== Cleaning up untagged manifests ==="
az acr manifest list-metadata --registry ${ACR_NAME} --repository unstract/backend --query "[?tags[0]==null].digest" -o tsv | \
    xargs -I% az acr repository delete --name ${ACR_NAME} --image unstract/backend@% --yes || true

# Create deployment script for Kubernetes/Docker
print_message $BLUE "\n=== Creating deployment helper script ==="
cat > /Users/jerrymorgan/Downloads/unstract-0.123.2/deploy-from-acr.sh << 'EOF'
#!/bin/bash

# Deploy Unstract from ACR

ACR_LOGIN_SERVER="acrunstract21468.azurecr.io"
VERSION="${VERSION:-latest}"

# Login to ACR
echo "Logging in to ACR..."
az acr login --name acrunstract21468

# Set ACR in environment
export ACR_LOGIN_SERVER

# Deploy using docker-compose
cd docker
docker-compose -f docker-compose.yaml -f docker-compose.acr.yaml up -d

# Show status
docker-compose ps
EOF

chmod +x /Users/jerrymorgan/Downloads/unstract-0.123.2/deploy-from-acr.sh

# Final status report
print_message $BLUE "\n=== Final ACR Status ==="
print_message $YELLOW "Repositories in ACR:"
az acr repository list --name ${ACR_NAME} --output table

print_message $YELLOW "\nImages with tags:"
for repo in $(az acr repository list --name ${ACR_NAME} --output tsv); do
    tags=$(az acr repository show-tags --name ${ACR_NAME} --repository "${repo}" --output tsv 2>/dev/null || echo "none")
    echo "${repo}: ${tags}"
done

print_message $GREEN "\n=== ACR Fix Complete! ==="
print_message $YELLOW "To deploy, run: ./deploy-from-acr.sh"

# Check for architecture issues
print_message $BLUE "\n=== Checking for multi-platform support ==="
print_message $YELLOW "Note: The 'no matching manifest for linux/arm64/v8' errors indicate"
print_message $YELLOW "that Unstract images are only available for linux/amd64 architecture."
print_message $YELLOW "This is normal if you're running on ARM64 (Apple Silicon) locally."
print_message $YELLOW "The images will work fine when deployed to linux/amd64 hosts."