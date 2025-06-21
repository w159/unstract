#!/bin/bash

# Unstract Deployment Script
# This script manages the deployment of Unstract containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_DIR="${SCRIPT_DIR}/docker"

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_message $RED "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to delete all containers
delete_containers() {
    print_message $YELLOW "Stopping and removing all Unstract containers..."
    
    # Stop all containers
    docker-compose -f "${DOCKER_DIR}/docker-compose.yaml" down -v || true
    
    # Remove any remaining containers with unstract in name
    docker ps -a --filter "name=unstract" -q | xargs -r docker rm -f || true
    
    print_message $GREEN "All containers have been removed."
}

# Function to clean up volumes and networks
clean_resources() {
    print_message $YELLOW "Cleaning up volumes and networks..."
    
    # Remove volumes
    docker volume ls --filter "name=unstract" -q | xargs -r docker volume rm || true
    
    # Remove network
    docker network rm unstract-network || true
    
    print_message $GREEN "Resources cleaned up."
}

# Function to check environment files
check_env_files() {
    print_message $YELLOW "Checking environment files..."
    
    local env_files=(
        "${SCRIPT_DIR}/backend/.env"
        "${SCRIPT_DIR}/platform-service/.env"
        "${SCRIPT_DIR}/prompt-service/.env"
        "${SCRIPT_DIR}/x2text-service/.env"
        "${SCRIPT_DIR}/runner/.env"
        "${DOCKER_DIR}/essentials.env"
    )
    
    local missing_files=()
    
    for env_file in "${env_files[@]}"; do
        if [ ! -f "$env_file" ]; then
            missing_files+=("$env_file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_message $RED "Missing environment files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        print_message $YELLOW "Creating from samples..."
        
        # Try to create from samples
        for file in "${missing_files[@]}"; do
            sample_file="${file%.env}sample.env"
            if [ -f "$sample_file" ]; then
                cp "$sample_file" "$file"
                print_message $GREEN "Created $file from $sample_file"
            else
                print_message $RED "No sample file found for $file"
            fi
        done
    else
        print_message $GREEN "All environment files present."
    fi
}

# Function to set default environment variables
set_defaults() {
    # Set default VERSION if not set
    export VERSION=${VERSION:-"latest"}
    
    # Set default worker autoscaling
    export WORKER_AUTOSCALE=${WORKER_AUTOSCALE:-"1,3"}
    export WORKER_LOGGING_AUTOSCALE=${WORKER_LOGGING_AUTOSCALE:-"1,2"}
    export WORKER_FILE_PROCESSING_AUTOSCALE=${WORKER_FILE_PROCESSING_AUTOSCALE:-"1,3"}
    export WORKER_FILE_PROCESSING_CALLBACK_AUTOSCALE=${WORKER_FILE_PROCESSING_CALLBACK_AUTOSCALE:-"1,3"}
    
    # Set tool registry config path
    export TOOL_REGISTRY_CONFIG_SRC_PATH=${TOOL_REGISTRY_CONFIG_SRC_PATH:-"${DOCKER_DIR}/workflow_data/tool_registry_config"}
}

# Function to deploy containers
deploy_containers() {
    print_message $YELLOW "Deploying Unstract containers..."
    
    cd "${DOCKER_DIR}"
    
    # Pull latest images
    print_message $YELLOW "Pulling latest images..."
    docker-compose pull
    
    # Start containers
    print_message $YELLOW "Starting containers..."
    docker-compose up -d
    
    print_message $GREEN "Containers deployed successfully!"
}

# Function to show container status
show_status() {
    print_message $YELLOW "\nContainer Status:"
    docker-compose -f "${DOCKER_DIR}/docker-compose.yaml" ps
    
    print_message $YELLOW "\nService URLs:"
    echo "  - Frontend: http://frontend.unstract.localhost:3000"
    echo "  - Backend API: http://frontend.unstract.localhost:8000"
    echo "  - Celery Flower: http://localhost:5555"
    echo "  - Platform Service: http://localhost:3001"
    echo "  - Prompt Service: http://localhost:3003"
    echo "  - X2Text Service: http://localhost:3004"
    echo "  - Runner Service: http://localhost:5002"
}

# Function to show logs
show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        docker-compose -f "${DOCKER_DIR}/docker-compose.yaml" logs -f
    else
        docker-compose -f "${DOCKER_DIR}/docker-compose.yaml" logs -f "$service"
    fi
}

# Main function
main() {
    case "${1}" in
        "delete")
            check_docker
            delete_containers
            clean_resources
            ;;
        "deploy")
            check_docker
            check_env_files
            set_defaults
            deploy_containers
            show_status
            ;;
        "redeploy")
            check_docker
            delete_containers
            clean_resources
            check_env_files
            set_defaults
            deploy_containers
            show_status
            ;;
        "status")
            check_docker
            show_status
            ;;
        "logs")
            check_docker
            show_logs "${2}"
            ;;
        *)
            print_message $YELLOW "Unstract Deployment Script"
            echo ""
            echo "Usage: $0 {delete|deploy|redeploy|status|logs [service]}"
            echo ""
            echo "Commands:"
            echo "  delete    - Stop and remove all containers, volumes, and networks"
            echo "  deploy    - Deploy all containers"
            echo "  redeploy  - Delete everything and deploy fresh"
            echo "  status    - Show container status"
            echo "  logs      - Show logs (optionally for specific service)"
            echo ""
            echo "Examples:"
            echo "  $0 delete"
            echo "  $0 deploy"
            echo "  $0 redeploy"
            echo "  $0 status"
            echo "  $0 logs"
            echo "  $0 logs backend"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"