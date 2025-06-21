#!/bin/bash
# Full Unstract System Restart with Verification

echo "=== Full Unstract System Restart ==="
echo ""

# Set environment variables
export VERSION=latest
export DOCKER_DEFAULT_PLATFORM=linux/amd64

echo "1. Stopping all containers..."
cd docker 2>/dev/null || cd /Users/jerrymorgan/Downloads/unstract-0.123.2/docker
docker-compose down

echo ""
echo "2. Cleaning up..."
docker system prune -f

echo ""
echo "3. Starting fresh deployment..."
docker-compose -f docker-compose.yaml -f docker-compose-dev-essentials.yaml up -d

echo ""
echo "4. Waiting for services to start (30 seconds)..."
sleep 30

echo ""
echo "5. Verifying services..."
echo "Checking containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep unstract

echo ""
echo "6. Testing endpoints..."

# Test Frontend
echo -n "Frontend (http://localhost:3000): "
if curl -s -I http://localhost:3000 | grep -q "200 OK"; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

# Test Backend
echo -n "Backend API (http://localhost:8000): "
if curl -s http://localhost:8000/api/v1/health 2>&1 | grep -q "Unauthorized"; then
    echo "✅ OK (Auth required)"
else
    echo "❌ Failed"
fi

# Test MinIO
echo -n "MinIO Console (http://localhost:9001): "
if curl -s -I http://localhost:9001 | grep -q "200 OK"; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

# Test RabbitMQ
echo -n "RabbitMQ (http://localhost:15672): "
if curl -s -I http://localhost:15672 | grep -q "200 OK"; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

echo ""
echo "=== ACCESS INFORMATION ==="
echo ""
echo "Main Application:"
echo "  URL: http://localhost:3000"
echo "  Login: unstract / unstract"
echo ""
echo "If 'Please wait...' persists:"
echo "  1. Open Chrome DevTools (F12)"
echo "  2. Go to Application tab"
echo "  3. Clear Site Data"
echo "  4. Hard refresh (Ctrl+Shift+R)"
echo ""
echo "Alternative: Try incognito mode"
echo ""
echo "Other Services:"
echo "  - MinIO: http://localhost:9001 (minio/minio123)"
echo "  - RabbitMQ: http://localhost:15672 (admin/password)"
echo "  - API Docs: http://localhost:8000/api/v1/docs"
echo ""
echo "For detailed credentials, see: CORRECT-CREDENTIALS.md"