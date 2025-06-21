#!/bin/bash
# Final fix for frontend.unstract.localhost

echo "=== Final Fix for Frontend Routing ==="

# The issue is that the frontend label in docker-compose.yaml doesn't specify the port
# Let's add it to the override file with the correct port

cd docker

# Create a proper override that forces Traefik to use port 80
cat > docker-compose.override.yaml << 'EOF'
version: "3.9"
services:
  frontend:
    labels:
      - traefik.enable=true
      - traefik.http.routers.frontend.rule=Host(`frontend.unstract.localhost`) && !PathPrefix(`/api/v1`, `/deployment`)
      - traefik.http.services.frontend.loadbalancer.server.port=80
      - traefik.docker.network=unstract-network
EOF

echo "Override file created with correct port configuration"

# Restart just the frontend and proxy
echo "Restarting services..."
docker-compose restart frontend reverse-proxy

echo "Waiting for services to stabilize..."
sleep 10

echo "Testing frontend.unstract.localhost..."
if curl -s -I http://frontend.unstract.localhost | grep -q "200 OK"; then
    echo "✅ Success! Frontend is now accessible at http://frontend.unstract.localhost"
else
    echo "❌ Still having issues. Checking Traefik dashboard..."
    echo "Visit http://localhost:8080 to debug Traefik routing"
fi