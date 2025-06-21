#!/bin/bash
# Fix Traefik routing for Unstract on Mac

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Fixing Traefik Routing for Unstract ===${NC}"

# 1. Update hosts file entries
echo -e "${YELLOW}Updating /etc/hosts entries...${NC}"
HOSTS_UPDATED=false

# Remove old entries and add new ones
sudo sed -i '' '/unstract.localhost/d' /etc/hosts 2>/dev/null || true

# Add all required hosts entries
echo "# Unstract development hosts" | sudo tee -a /etc/hosts > /dev/null
echo "127.0.0.1 unstract.localhost" | sudo tee -a /etc/hosts > /dev/null
echo "127.0.0.1 frontend.unstract.localhost" | sudo tee -a /etc/hosts > /dev/null
echo "127.0.0.1 backend.unstract.localhost" | sudo tee -a /etc/hosts > /dev/null
echo "127.0.0.1 api.unstract.localhost" | sudo tee -a /etc/hosts > /dev/null

echo -e "${GREEN}Hosts file updated${NC}"

# 2. Create a docker-compose override for simplified routing
echo -e "${YELLOW}Creating docker-compose override for development...${NC}"

cat > docker/docker-compose.override.yaml << 'EOF'
version: '3.9'

services:
  reverse-proxy:
    command:
      - --api.insecure=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --log.level=DEBUG

  backend:
    labels:
      - traefik.enable=true
      - traefik.http.routers.backend.rule=Host(`backend.unstract.localhost`) || (Host(`unstract.localhost`) && PathPrefix(`/api`))
      - traefik.http.routers.backend.entrypoints=web
      - traefik.http.services.backend.loadbalancer.server.port=8000

  frontend:
    labels:
      - traefik.enable=true
      - traefik.http.routers.frontend.rule=Host(`frontend.unstract.localhost`) || Host(`unstract.localhost`)
      - traefik.http.routers.frontend.entrypoints=web
      - traefik.http.services.frontend.loadbalancer.server.port=3000
      - traefik.http.routers.frontend.priority=1
      - traefik.http.routers.backend.priority=10
EOF

echo -e "${GREEN}Docker compose override created${NC}"

# 3. Restart containers with new configuration
echo -e "${YELLOW}Restarting containers with new configuration...${NC}"

cd docker

# Stop current containers
docker-compose down

# Start with override configuration
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker-compose up -d

cd ..

# 4. Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# 5. Test endpoints
echo -e "${BLUE}=== Testing Endpoints ===${NC}"

# Test Traefik dashboard
echo -n "Traefik Dashboard (http://localhost:8080): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

# Test main site
echo -n "Main site (http://unstract.localhost): "
if curl -s -o /dev/null -w "%{http_code}" http://unstract.localhost | grep -q "200"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

# Test frontend direct
echo -n "Frontend (http://frontend.unstract.localhost): "
if curl -s -o /dev/null -w "%{http_code}" http://frontend.unstract.localhost | grep -q "200"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

# Test API
echo -n "API (http://unstract.localhost/api/v1/health): "
if curl -s -o /dev/null -w "%{http_code}" http://unstract.localhost/api/v1/health | grep -q "200"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

echo -e "${BLUE}=== Access URLs ===${NC}"
echo -e "${GREEN}Main Application:${NC} http://unstract.localhost"
echo -e "${GREEN}Frontend Direct:${NC} http://frontend.unstract.localhost"
echo -e "${GREEN}Backend API:${NC} http://backend.unstract.localhost"
echo -e "${GREEN}Traefik Dashboard:${NC} http://localhost:8080"
echo ""
echo -e "${YELLOW}You can also access services directly via ports:${NC}"
echo -e "Frontend: http://localhost:3000"
echo -e "Backend: http://localhost:8000"