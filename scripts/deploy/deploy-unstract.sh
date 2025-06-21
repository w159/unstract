#!/bin/bash
# Unified Deployment Script for Unstract
# Supports local, production, and cloud deployments

set -e

# Default values
DEPLOYMENT_TYPE="local"
COMPOSE_FILE="docker/docker-compose.yaml"
ENVIRONMENT="development"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --production)
            DEPLOYMENT_TYPE="production"
            COMPOSE_FILE="docker/docker-compose-production.yaml"
            ENVIRONMENT="production"
            shift
            ;;
        --acr)
            DEPLOYMENT_TYPE="acr"
            COMPOSE_FILE="docker/docker-compose.acr.yaml"
            shift
            ;;
        --mac)
            export DOCKER_DEFAULT_PLATFORM=linux/amd64
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --production  Deploy production configuration"
            echo "  --acr         Deploy from Azure Container Registry"
            echo "  --mac         Set platform for Mac M1/M2"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Pre-deployment checks
pre_deployment_checks() {
    print_status "Running pre-deployment checks..."
    
    # Check if setup has been run
    if [ ! -f backend/.env ]; then
        print_warning "Environment not set up. Running setup first..."
        ./scripts/setup/setup-environment.sh
    fi
    
    # Verify compose file exists
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running"
        exit 1
    fi
}

# Stop existing deployment
stop_existing() {
    if docker compose -f "$COMPOSE_FILE" ps -q 2>/dev/null | grep -q .; then
        print_status "Stopping existing deployment..."
        docker compose -f "$COMPOSE_FILE" down
    fi
}

# Deploy services
deploy_services() {
    print_status "Deploying Unstract ($DEPLOYMENT_TYPE)..."
    
    # Set environment variables
    export COMPOSE_PROJECT_NAME="unstract"
    export ENVIRONMENT="$ENVIRONMENT"
    
    # Pull latest images if using ACR
    if [ "$DEPLOYMENT_TYPE" = "acr" ]; then
        print_status "Pulling images from ACR..."
        docker compose -f "$COMPOSE_FILE" pull
    fi
    
    # Start services
    print_status "Starting services..."
    docker compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to be healthy
    print_status "Waiting for services to be healthy..."
    sleep 10
    
    # Check service health
    check_service_health
}

# Check service health
check_service_health() {
    print_status "Checking service health..."
    
    local unhealthy=0
    local services=$(docker compose -f "$COMPOSE_FILE" ps --format json | jq -r '.Service')
    
    for service in $services; do
        local status=$(docker compose -f "$COMPOSE_FILE" ps --format json | jq -r "select(.Service==\"$service\") | .State")
        if [ "$status" = "running" ]; then
            echo -e "  ${GREEN}✓${NC} $service: running"
        else
            echo -e "  ${RED}✗${NC} $service: $status"
            unhealthy=$((unhealthy + 1))
        fi
    done
    
    if [ $unhealthy -gt 0 ]; then
        print_warning "$unhealthy services are not healthy"
        print_warning "Check logs with: docker compose -f $COMPOSE_FILE logs"
    else
        print_status "All services are healthy!"
    fi
}

# Post-deployment tasks
post_deployment() {
    print_status "Running post-deployment tasks..."
    
    # Run database migrations
    if [ "$DEPLOYMENT_TYPE" != "acr" ]; then
        print_status "Running database migrations..."
        docker compose -f "$COMPOSE_FILE" exec -T backend python manage.py migrate || print_warning "Migration failed or already applied"
    fi
    
    # Create superuser if needed
    if [ "$ENVIRONMENT" = "development" ]; then
        print_status "Creating default superuser (if not exists)..."
        docker compose -f "$COMPOSE_FILE" exec -T backend python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
    print('Superuser created')
else:
    print('Superuser already exists')
" || print_warning "Could not create superuser"
    fi
}

# Display access information
show_access_info() {
    echo
    echo "========================================="
    echo "Unstract Deployment Complete!"
    echo "========================================="
    echo
    echo "Access URLs:"
    echo "  Frontend: http://localhost:3000"
    echo "  Backend API: http://localhost:8000/api/v1"
    
    if [ "$ENVIRONMENT" = "development" ]; then
        echo "  Django Admin: http://localhost:8000/admin"
        echo "    Username: admin"
        echo "    Password: admin"
    fi
    
    echo
    echo "Useful commands:"
    echo "  View logs: docker compose -f $COMPOSE_FILE logs -f"
    echo "  Stop services: docker compose -f $COMPOSE_FILE down"
    echo "  Restart services: docker compose -f $COMPOSE_FILE restart"
    echo
}

# Main deployment flow
main() {
    echo "=== Unstract Deployment Script ==="
    echo "Deployment Type: $DEPLOYMENT_TYPE"
    echo "Environment: $ENVIRONMENT"
    echo
    
    pre_deployment_checks
    stop_existing
    deploy_services
    post_deployment
    show_access_info
}

# Run main function
main "$@"