#!/bin/bash
# Fix frontend nginx configuration

echo "Fixing frontend nginx configuration..."

# Create custom nginx config that listens on port 3000
cat > nginx-frontend.conf << 'EOF'
server {
    listen 3000;
    server_name _;
    
    root /usr/share/nginx/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://unstract-backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /config/runtime-config.js {
        add_header Content-Type application/javascript;
        return 200 'window.REACT_APP_BACKEND_URL = "/api/v1";';
    }
}
EOF

# Copy config to container
docker cp nginx-frontend.conf unstract-frontend:/etc/nginx/conf.d/default.conf

# Reload nginx
docker exec unstract-frontend nginx -s reload

echo "Frontend nginx fixed. Testing..."
sleep 2

# Test
if curl -s http://localhost:3000 | grep -q "</html>"; then
    echo "✓ Frontend is now accessible at http://localhost:3000"
else
    echo "✗ Frontend still not working, checking logs..."
    docker logs unstract-frontend --tail 10
fi