#!/bin/bash
# Quick fix for Docker on Mac with Apple Silicon

echo "Fixing Docker for Apple Silicon Mac..."

# Export platform variable
export DOCKER_DEFAULT_PLATFORM=linux/amd64
export VERSION=latest

# Update docker/.env
if [ -f "docker/.env" ]; then
    if ! grep -q "DOCKER_DEFAULT_PLATFORM" docker/.env; then
        echo "DOCKER_DEFAULT_PLATFORM=linux/amd64" >> docker/.env
    fi
else
    cat > docker/.env << EOF
VERSION=latest
COMPOSE_PROJECT_NAME=unstract
DOCKER_DEFAULT_PLATFORM=linux/amd64
EOF
fi

echo "Fixed! Now you can run:"
echo ""
echo "Option 1: Use the Mac-specific script:"
echo "  ./deploy-unstract-mac.sh deploy"
echo ""
echo "Option 2: Use original script with platform override:"
echo "  DOCKER_DEFAULT_PLATFORM=linux/amd64 ./deploy-unstract.sh deploy"
echo ""
echo "Make sure 'Use Rosetta for x86_64/amd64 emulation' is enabled in Docker Desktop!"