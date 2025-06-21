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
