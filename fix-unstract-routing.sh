#!/bin/bash
# Fix Unstract routing to work as intended with frontend.unstract.localhost

set -e

echo "=== Fixing Unstract Routing Setup ==="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. First, ensure the hosts file has the correct entry
echo -e "${BLUE}Checking hosts file...${NC}"
if ! grep -q "frontend.unstract.localhost" /etc/hosts; then
    echo "127.0.0.1 frontend.unstract.localhost" | sudo tee -a /etc/hosts
    echo -e "${GREEN}Added frontend.unstract.localhost to hosts file${NC}"
else
    echo -e "${GREEN}Hosts file already configured${NC}"
fi

# 2. Create an empty proxy_overrides.yaml if it doesn't exist
# The docker-compose expects this file but we'll use the default Traefik labels
echo -e "${BLUE}Creating proxy_overrides.yaml...${NC}"
cd docker
touch proxy_overrides.yaml
echo -e "${GREEN}Created empty proxy_overrides.yaml${NC}"

# 3. Set the VERSION environment variable
export VERSION="${VERSION:-latest}"
export DOCKER_DEFAULT_PLATFORM=linux/amd64

# 4. Stop all containers
echo -e "${BLUE}Stopping all containers...${NC}"
docker-compose down || true

# 5. Fix the frontend port mapping
# The frontend nginx listens on port 80, not 3000
echo -e "${BLUE}Creating docker-compose.override.yaml with correct port mapping...${NC}"
cat > docker-compose.override.yaml << 'EOF'
services:
  frontend:
    ports:
      - "3000:80"  # Map host 3000 to container port 80 where nginx listens
    labels:
      - traefik.enable=true
      - traefik.http.routers.frontend.rule=Host(`frontend.unstract.localhost`)
      - traefik.http.services.frontend.loadbalancer.server.port=80

  backend:
    labels:
      - traefik.enable=true
      - traefik.http.routers.backend.rule=Host(`frontend.unstract.localhost`) && PathPrefix(`/api/v1`, `/deployment`)
      - traefik.http.services.backend.loadbalancer.server.port=8000

  reverse-proxy:
    labels:
      - traefik.enable=true
EOF

echo -e "${GREEN}Created docker-compose.override.yaml${NC}"

# 6. Start services using the proper compose files
echo -e "${BLUE}Starting services with proper configuration...${NC}"
VERSION=$VERSION DOCKER_DEFAULT_PLATFORM=linux/amd64 docker-compose -f docker-compose.yaml -f docker-compose-dev-essentials.yaml up -d

# 7. Wait for services to start
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 10

# 8. Check service status
echo -e "${BLUE}Checking service status...${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(proxy|frontend|backend)" || true

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${BLUE}Access Unstract at:${NC}"
echo -e "  Main App: ${GREEN}http://frontend.unstract.localhost${NC}"
echo -e "  MinIO Console: ${GREEN}http://localhost:9001${NC} (user: minio, pass: minio123)"
echo -e "  Traefik Dashboard: ${GREEN}http://localhost:8080${NC}"
echo ""
echo -e "${YELLOW}If you still get a bad gateway error, wait a few more seconds for services to fully start.${NC}"
echo -e "${YELLOW}Check logs with: docker-compose logs -f frontend backend reverse-proxy${NC}"