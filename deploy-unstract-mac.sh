#!/bin/bash
# Unstract Deployment Script for Mac (Apple Silicon)
# This script handles ARM64 compatibility issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Set environment variables
export VERSION="${VERSION:-latest}"
export DOCKER_DEFAULT_PLATFORM=linux/amd64

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check Docker Desktop settings
check_docker_settings() {
    print_message $BLUE "=== Checking Docker Desktop Settings ==="
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_message $RED "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    
    # Check if Rosetta is enabled (for Apple Silicon)
    if [[ $(uname -m) == "arm64" ]]; then
        print_message $YELLOW "Apple Silicon Mac detected. Using x86_64 emulation..."
        
        # Check Docker version
        docker_version=$(docker version --format '{{.Client.Version}}')
        print_message $GREEN "Docker version: $docker_version"
        
        print_message $YELLOW "IMPORTANT: Make sure 'Use Rosetta for x86_64/amd64 emulation' is enabled in Docker Desktop settings!"
        print_message $YELLOW "Settings > General > Use Rosetta for x86_64/amd64 emulation"
        
        read -p "Have you enabled Rosetta emulation in Docker Desktop? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message $RED "Please enable Rosetta emulation and try again."
            exit 1
        fi
    fi
}

# Function to set up environment
setup_environment() {
    print_message $BLUE "=== Setting up environment ==="
    
    # Create .env file if it doesn't exist
    if [ ! -f "docker/.env" ]; then
        print_message $YELLOW "Creating docker/.env file..."
        cat > docker/.env << EOF
VERSION=latest
COMPOSE_PROJECT_NAME=unstract
DOCKER_DEFAULT_PLATFORM=linux/amd64
EOF
    else
        # Add platform setting if not present
        if ! grep -q "DOCKER_DEFAULT_PLATFORM" docker/.env; then
            echo "DOCKER_DEFAULT_PLATFORM=linux/amd64" >> docker/.env
        fi
    fi
    
    # Source the env file
    set -a
    source docker/.env
    set +a
    
    print_message $GREEN "Environment configured for Mac deployment"
}

# Function to deploy with platform override
deploy_with_platform() {
    print_message $BLUE "=== Deploying Unstract containers with AMD64 platform ==="
    
    cd docker
    
    # Deploy essential services first
    print_message $YELLOW "Deploying essential services..."
    DOCKER_DEFAULT_PLATFORM=linux/amd64 docker-compose \
        -f docker-compose-dev-essentials.yaml \
        up -d --force-recreate
    
    # Wait for essential services
    print_message $YELLOW "Waiting for essential services to be ready..."
    sleep 10
    
    # Deploy main services
    print_message $YELLOW "Deploying main services..."
    DOCKER_DEFAULT_PLATFORM=linux/amd64 docker-compose \
        -f docker-compose.yaml \
        up -d --force-recreate
    
    cd ..
}

# Function to check deployment status
check_status() {
    print_message $BLUE "=== Checking deployment status ==="
    
    cd docker
    docker-compose -f docker-compose-dev-essentials.yaml -f docker-compose.yaml ps
    cd ..
    
    print_message $GREEN "Services URLs:"
    print_message $YELLOW "Frontend: http://localhost"
    print_message $YELLOW "Backend API: http://localhost/api"
    print_message $YELLOW "RabbitMQ: http://localhost:15672 (guest/guest)"
    print_message $YELLOW "MinIO: http://localhost:9001 (unstract/unstract-admin)"
}

# Function to clean up
cleanup() {
    print_message $BLUE "=== Cleaning up Unstract deployment ==="
    
    cd docker
    docker-compose -f docker-compose.yaml down -v --remove-orphans
    docker-compose -f docker-compose-dev-essentials.yaml down -v --remove-orphans
    cd ..
    
    print_message $GREEN "Cleanup complete"
}

# Function to show logs
show_logs() {
    local service=$1
    cd docker
    if [ -z "$service" ]; then
        docker-compose -f docker-compose-dev-essentials.yaml -f docker-compose.yaml logs -f
    else
        docker-compose -f docker-compose-dev-essentials.yaml -f docker-compose.yaml logs -f $service
    fi
    cd ..
}

# Main script logic
case "$1" in
    deploy)
        check_docker_settings
        setup_environment
        deploy_with_platform
        check_status
        ;;
    delete|cleanup)
        cleanup
        ;;
    redeploy)
        cleanup
        check_docker_settings
        setup_environment
        deploy_with_platform
        check_status
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs $2
        ;;
    *)
        print_message $BLUE "Unstract Mac Deployment Script"
        echo
        echo "Usage: $0 {deploy|delete|redeploy|status|logs [service]}"
        echo
        echo "Commands:"
        echo "  deploy    - Deploy all containers with Mac compatibility"
        echo "  delete    - Stop and remove all containers"
        echo "  redeploy  - Delete everything and deploy fresh"
        echo "  status    - Show container status"
        echo "  logs      - Show logs (optionally for specific service)"
        echo
        echo "This script handles Apple Silicon compatibility by:"
        echo "- Setting DOCKER_DEFAULT_PLATFORM=linux/amd64"
        echo "- Using Rosetta emulation for x86_64 containers"
        echo
        exit 1
        ;;
esac