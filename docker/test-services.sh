#!/bin/bash
# Test all Unstract services

echo "=== Testing Unstract Services ==="
echo ""

# Test Backend API
echo "1. Backend API (Port 8000):"
echo -n "   Health Check: "
if curl -s http://localhost:8000/api/v1/health 2>/dev/null | grep -q "Unauthorized"; then
    echo "✓ Working (requires auth)"
else
    echo "✗ Not responding"
fi

# Test Frontend 
echo ""
echo "2. Frontend (Port 3000):"
echo -n "   Direct nginx test: "
docker exec unstract-frontend sh -c "wget -q -O- http://localhost:80 2>&1 | head -1" || echo "nginx not on port 80"
echo -n "   Port 3000 test: "
docker exec unstract-frontend sh -c "netstat -tuln 2>/dev/null | grep 3000" || echo "Nothing listening on 3000"

# Test MinIO
echo ""
echo "3. MinIO (Port 9001):"
echo -n "   Console: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:9001 | grep -q "200"; then
    echo "✓ Working"
    echo "   Credentials: Username=minio, Password=minio123"
else
    echo "✗ Not responding"
fi

# Check what's actually running
echo ""
echo "4. Running Services:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAME|unstract)" | head -10

echo ""
echo "=== Recommendations ==="
echo "Since the frontend container port mapping isn't working properly,"
echo "you can access the backend API directly at: http://localhost:8000"
echo ""
echo "To login to the backend API:"
echo "1. Go to http://localhost:8000/api/v1/login"
echo "2. Use default credentials (check backend/.env for details)"
echo ""
echo "MinIO console is working at: http://localhost:9001"
echo "Use: username=minio, password=minio123"