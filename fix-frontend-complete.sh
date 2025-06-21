#!/bin/bash
# Complete fix for frontend communication

echo "=== Complete Frontend Fix ==="

# The real issue: Frontend needs proper API configuration
# Let's check what the frontend expects

echo "1. Checking frontend configuration..."
docker exec unstract-frontend ls -la /usr/share/nginx/html/static/js/*.js | head -5

echo ""
echo "2. Creating proper runtime config with API endpoint..."
cat > docker/runtime-config.js << 'EOF'
// This file is auto-generated at runtime. Do not modify manually.
window.RUNTIME_CONFIG = {
  faviconPath: "",
  logoUrl: "",
  apiUrl: "/api/v1",
  wsUrl: "ws://localhost:8000"
};

// Additional config for API endpoints
window.API_BASE_URL = "http://localhost:8000";
window.WS_BASE_URL = "ws://localhost:8000";
EOF

echo "3. Copying config to frontend..."
docker cp docker/runtime-config.js unstract-frontend:/usr/share/nginx/html/config/runtime-config.js

echo "4. Updating nginx to properly proxy API calls..."
cat > docker/nginx-fixed.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    root /usr/share/nginx/html;
    index index.html;
    
    # Main app
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # API proxy to backend
    location /api/ {
        proxy_pass http://unstract-backend:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
    
    # WebSocket proxy
    location /socket.io/ {
        proxy_pass http://unstract-backend:8000/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Deployment endpoint
    location /deployment {
        proxy_pass http://unstract-backend:8000/deployment;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

echo "5. Applying nginx config..."
docker cp docker/nginx-fixed.conf unstract-frontend:/etc/nginx/conf.d/default.conf

echo "6. Restarting nginx..."
docker exec unstract-frontend nginx -s reload

echo "7. Clear browser cache and cookies for the site"

echo ""
echo "✅ Fix applied! Please:"
echo "1. Clear your browser cache (Ctrl+Shift+Delete)"
echo "2. Open http://localhost:3000 in an incognito/private window"
echo "3. Login with: unstract / unstract"
echo ""
echo "Alternative access:"
echo "- Direct backend API: http://localhost:8000/api/v1/docs"