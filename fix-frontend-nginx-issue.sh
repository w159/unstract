#!/bin/bash
# Fix frontend nginx io_setup issue

echo "=== Fixing Frontend Loading Issue ==="

# The issue is nginx trying to use AIO which doesn't work on Mac Docker
# We need to create a custom nginx config without AIO

# First, let's check the current frontend config
echo "Creating custom nginx config without AIO..."

cat > docker/nginx-custom.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    root /usr/share/nginx/html;
    index index.html;
    
    # Disable AIO which causes issues on Mac
    # Remove any aio directives
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Proxy API calls to backend
    location /api {
        proxy_pass http://unstract-backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Handle WebSocket connections
    location /socket.io {
        proxy_pass http://unstract-backend:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Serve static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

echo "Copying config to frontend container..."
docker cp docker/nginx-custom.conf unstract-frontend:/etc/nginx/conf.d/default.conf

echo "Restarting nginx in frontend container..."
docker exec unstract-frontend nginx -s reload

echo "Waiting for services to stabilize..."
sleep 5

echo "Testing frontend..."
if curl -s http://localhost:3000 | grep -q "Unstract"; then
    echo "✅ Frontend is now working!"
    echo "Access it at: http://frontend.unstract.localhost or http://localhost:3000"
else
    echo "❌ Still having issues. Trying alternative fix..."
    
    # Alternative: restart the whole frontend container
    echo "Restarting frontend container..."
    docker restart unstract-frontend
    
    sleep 10
    
    echo "Frontend should now be accessible at http://localhost:3000"
fi

echo ""
echo "If you're still seeing 'Please wait...' message:"
echo "1. Clear your browser cache"
echo "2. Open browser console (F12) and check for errors"
echo "3. Make sure you're using http://localhost:3000 instead of https"