#!/bin/bash
# Consolidated Environment Setup Script for Unstract
# This script handles all common setup tasks and fixes known issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running on macOS
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

# Fix Docker Desktop for Mac DNS issues
fix_mac_docker_dns() {
    if is_macos; then
        print_status "Fixing Docker Desktop DNS for macOS..."
        docker run --rm busybox nslookup google.com || {
            print_warning "DNS issue detected. Applying fix..."
            # Reset Docker Desktop networking
            osascript -e 'quit app "Docker"'
            sleep 5
            open -a Docker
            print_status "Waiting for Docker to restart..."
            sleep 30
        }
    fi
}

# Setup environment files
setup_env_files() {
    print_status "Setting up environment files..."

    # Backend env
    if [ ! -f backend/.env ]; then
        cp backend/sample.env backend/.env
        print_status "Created backend/.env from sample"
    fi

    # Frontend env
    if [ ! -f frontend/.env ]; then
        cp frontend/sample.env frontend/.env
        print_status "Created frontend/.env from sample"
    fi

    # Docker env files
    for service in platform-service prompt-service runner tool-sidecar x2text-service; do
        if [ ! -f $service/.env ]; then
            cp $service/sample.env $service/.env 2>/dev/null || print_warning "No sample.env for $service"
        fi
    done

    # Generate secure keys
    if grep -q "GENERATE-A-SECURE-KEY" backend/.env; then
        print_status "Generating secure keys..."
        python3 -c "
import secrets
import os

env_file = 'backend/.env'
with open(env_file, 'r') as f:
    content = f.read()

# Generate different keys for different services
keys = {
    'INTERNAL_SERVICE_API_KEY': secrets.token_urlsafe(32),
    'BUILTIN_FUNCTIONS_API_KEY': secrets.token_urlsafe(32),
    'PLATFORM_SERVICE_API_KEY': secrets.token_urlsafe(32),
    'PROMPT_SERVICE_API_KEY': secrets.token_urlsafe(32),
    'X2TEXT_API_KEY': secrets.token_urlsafe(32),
}

for key_name, key_value in keys.items():
    content = content.replace(f'{key_name}=\"GENERATE-A-SECURE-KEY\"', f'{key_name}=\"{key_value}\"')

# Generate encryption key
from cryptography.fernet import Fernet
encryption_key = Fernet.generate_key().decode()
content = content.replace('ENCRYPTION_KEY=\"GENERATE-A-32-CHAR-KEY-AND-BACKUP\"', f'ENCRYPTION_KEY=\"{encryption_key}\"')

with open(env_file, 'w') as f:
    f.write(content)
"
        print_status "Secure keys generated"
    fi
}

# Fix Docker networking issues
fix_docker_networking() {
    print_status "Checking Docker networking..."

    # Ensure network exists
    docker network inspect unstract-network >/dev/null 2>&1 || {
        print_status "Creating unstract-network..."
        docker network create unstract-network
    }

    # Clean up any conflicting containers
    docker ps -a --format '{{.Names}}' | grep -E '^unstract-' | while read container; do
        if docker ps --format '{{.Names}}' | grep -q "^$container$"; then
            print_warning "Stopping conflicting container: $container"
            docker stop $container >/dev/null 2>&1
        fi
        docker rm $container >/dev/null 2>&1
    done
}

# Setup required directories
setup_directories() {
    print_status "Creating required directories..."
    mkdir -p workflow_data logs data

    # Set permissions for Docker volumes
    if [ -d workflow_data ]; then
        chmod -R 777 workflow_data
    fi
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed or not in PATH."
        exit 1
    fi

    # Check Python (for key generation)
    if ! command -v python3 &> /dev/null; then
        print_warning "Python 3 not found. Cannot generate secure keys automatically."
    fi
}

# Main setup flow
main() {
    echo "=== Unstract Environment Setup ==="
    echo

    check_prerequisites

    if is_macos; then
        fix_mac_docker_dns
    fi

    setup_env_files
    fix_docker_networking
    setup_directories

    print_status "Environment setup complete!"
    echo
    echo "To start Unstract, run:"
    echo "  docker compose -f docker/docker-compose.yaml up -d"
    echo
    echo "To view logs:"
    echo "  docker compose -f docker/docker-compose.yaml logs -f"
}

# Run main function
main "$@"