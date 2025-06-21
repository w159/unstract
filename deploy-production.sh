#!/bin/bash
set -e

echo "Unstract Production Deployment Script"
echo "===================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Set production domain
read -p "Enter your domain name (e.g., unstract.example.com): " DOMAIN
export DOMAIN

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting." >&2; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "Docker Compose is required but not installed. Aborting." >&2; exit 1; }

# Create necessary directories
echo "Creating directories..."
mkdir -p docker/certs
mkdir -p docker/workflow_data
mkdir -p logs

# Generate SSL certificates (self-signed for now, replace with Let's Encrypt)
if [ ! -f docker/certs/cert.pem ]; then
    echo "Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout docker/certs/key.pem \
        -out docker/certs/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"
fi

# Copy sample env files if they don't exist
echo "Setting up environment files..."
[ ! -f backend/.env ] && cp backend/.env.production backend/.env
[ ! -f frontend/.env ] && cp frontend/.env.production frontend/.env
[ ! -f platform-service/.env ] && cp platform-service/sample.env platform-service/.env
[ ! -f prompt-service/.env ] && cp prompt-service/sample.env prompt-service/.env
[ ! -f x2text-service/.env ] && cp x2text-service/sample.env x2text-service/.env
[ ! -f runner/.env ] && cp runner/sample.env runner/.env

# Update domain in env files
echo "Updating domain in configuration files..."
sed -i "s/your-domain.com/$DOMAIN/g" backend/.env
sed -i "s/your-domain.com/$DOMAIN/g" docker/traefik-dynamic.yaml

# Generate secure keys
echo "Generating secure keys..."
DJANGO_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -base64 32 | head -c 32)
INTERNAL_API_KEY=$(openssl rand -base64 32)
PLATFORM_API_KEY=$(openssl rand -base64 32)
PROMPT_API_KEY=$(openssl rand -base64 32)
X2TEXT_API_KEY=$(openssl rand -base64 32)

# Update keys in backend/.env
sed -i "s/DJANGO_SECRET_KEY=\".*\"/DJANGO_SECRET_KEY=\"$DJANGO_SECRET\"/g" backend/.env
sed -i "s/ENCRYPTION_KEY=\".*\"/ENCRYPTION_KEY=\"$ENCRYPTION_KEY\"/g" backend/.env
sed -i "s/INTERNAL_SERVICE_API_KEY=\".*\"/INTERNAL_SERVICE_API_KEY=\"$INTERNAL_API_KEY\"/g" backend/.env
sed -i "s/PLATFORM_SERVICE_API_KEY=\".*\"/PLATFORM_SERVICE_API_KEY=\"$PLATFORM_API_KEY\"/g" backend/.env
sed -i "s/PROMPT_SERVICE_API_KEY=\".*\"/PROMPT_SERVICE_API_KEY=\"$PROMPT_API_KEY\"/g" backend/.env
sed -i "s/X2TEXT_API_KEY=\".*\"/X2TEXT_API_KEY=\"$X2TEXT_API_KEY\"/g" backend/.env

# Generate Traefik dashboard password
echo "Setting up Traefik dashboard authentication..."
read -p "Enter username for Traefik dashboard [admin]: " TRAEFIK_USER
TRAEFIK_USER=${TRAEFIK_USER:-admin}
read -s -p "Enter password for Traefik dashboard: " TRAEFIK_PASS
echo
TRAEFIK_HASH=$(docker run --rm httpd:2.4-alpine htpasswd -nbB $TRAEFIK_USER "$TRAEFIK_PASS" | sed -e s/\\$/\\$\\$/g)
sed -i "s|admin:\$2y\$10\$YourHashedPasswordHere|$TRAEFIK_HASH|g" docker/traefik-dynamic.yaml

# Set version
export VERSION=${VERSION:-latest}

# Pull latest images
echo "Pulling Docker images..."
cd docker
docker-compose -f docker-compose-production.yaml pull

# Start services
echo "Starting services..."
docker-compose -f docker-compose-production.yaml up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Run database migrations
echo "Running database migrations..."
docker-compose -f docker-compose-production.yaml exec -T backend python manage.py migrate

# Create superuser
echo "Creating superuser..."
docker-compose -f docker-compose-production.yaml exec -T backend python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@$DOMAIN', 'changeme123')
    print("Superuser created. Username: admin, Password: changeme123")
else:
    print("Superuser already exists")
EOF

# Show status
echo ""
echo "Deployment complete!"
echo "==================="
echo "Frontend URL: https://$DOMAIN"
echo "Backend API: https://$DOMAIN/api/v1/"
echo "Traefik Dashboard: https://traefik.$DOMAIN"
echo "Default login: admin / changeme123 (CHANGE THIS!)"
echo ""
echo "IMPORTANT: Save these keys securely!"
echo "ENCRYPTION_KEY: $ENCRYPTION_KEY"
echo ""
echo "To view logs: docker-compose -f docker-compose-production.yaml logs -f"
echo "To stop services: docker-compose -f docker-compose-production.yaml down"