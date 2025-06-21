#!/bin/bash
# Simple local setup without Traefik routing complexity

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Simple Unstract Setup (No Traefik Routing) ===${NC}"

# Create a simplified docker-compose override
cat > docker/docker-compose.override.yaml << 'EOF'
version: '3.9'

services:
  # Disable Traefik labels and use direct ports
  backend:
    labels:
      - traefik.enable=false
    environment:
      - CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000
      - DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,backend,unstract-backend

  frontend:
    labels:
      - traefik.enable=false
    environment:
      - REACT_APP_API_URL=http://localhost:8000
      - REACT_APP_BACKEND_URL=http://localhost:8000/api/v1

  reverse-proxy:
    # Disable reverse proxy for now
    deploy:
      replicas: 0
EOF

echo -e "${GREEN}Created simplified configuration${NC}"

# Restart services
echo -e "${YELLOW}Restarting services...${NC}"
cd docker
docker-compose down
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker-compose up -d
cd ..

# Wait for services
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 15

# Test endpoints
echo -e "${BLUE}=== Testing Direct Access ===${NC}"

echo -n "Frontend (http://localhost:3000): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Starting...${NC}"
fi

echo -n "Backend API (http://localhost:8000/api/v1/health): "
if curl -s http://localhost:8000/api/v1/health | grep -q "health"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Starting...${NC}"
fi

echo -e "${BLUE}=== Access URLs ===${NC}"
echo -e "${GREEN}Frontend:${NC} http://localhost:3000"
echo -e "${GREEN}Backend API:${NC} http://localhost:8000"
echo -e "${GREEN}API Documentation:${NC} http://localhost:8000/api/v1/docs"
echo ""
echo -e "${YELLOW}Note: This setup bypasses Traefik for simplicity.${NC}"
echo -e "${YELLOW}The frontend and backend communicate directly via ports.${NC}"