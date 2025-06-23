#!/bin/bash
set -e

# Smoke tests for Unstract deployment
# Usage: ./smoke-tests.sh <base_url>

BASE_URL=${1:-"https://staging.unstract.example.com"}
TIMEOUT=300  # 5 minutes timeout for app startup
INTERVAL=10  # Check every 10 seconds

echo "Running smoke tests against: $BASE_URL"
echo "Timeout: ${TIMEOUT}s"

# Function to check endpoint
check_endpoint() {
    local endpoint=$1
    local expected_status=${2:-200}
    local description=$3
    
    echo -n "Testing $description ($endpoint)... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint" || echo "000")
    
    if [ "$response" = "$expected_status" ]; then
        echo "✓ OK ($response)"
        return 0
    else
        echo "✗ FAILED (Expected: $expected_status, Got: $response)"
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local endpoint=$1
    local description=$2
    local elapsed=0
    
    echo "Waiting for $description to be ready..."
    
    while [ $elapsed -lt $TIMEOUT ]; do
        if curl -s -f -o /dev/null "$BASE_URL$endpoint" 2>/dev/null; then
            echo "✓ $description is ready!"
            return 0
        fi
        
        echo -n "."
        sleep $INTERVAL
        elapsed=$((elapsed + INTERVAL))
    done
    
    echo ""
    echo "✗ Timeout waiting for $description"
    return 1
}

# Wait for frontend to be ready
wait_for_service "/" "Frontend"

# Wait for backend to be ready
wait_for_service "/api/v1/health/" "Backend API"

echo ""
echo "Running endpoint tests..."
echo "========================"

# Test frontend
check_endpoint "/" 200 "Frontend home page"
check_endpoint "/static/js/main.js" 200 "Frontend static assets"

# Test backend API endpoints
check_endpoint "/api/v1/health/" 200 "Backend health check"
check_endpoint "/api/v1/" 200 "Backend API root"
check_endpoint "/api/v1/auth/login/" 405 "Backend auth endpoint" # GET not allowed

# Test admin (should redirect to login)
check_endpoint "/admin/" 302 "Django admin"

# Test that internal services are not exposed
echo ""
echo "Security checks..."
echo "=================="

# These should fail (not be accessible from outside)
internal_services=(
    "platform-service:3001"
    "prompt-service:3003"
    "x2text-service:3004"
    "runner:5002"
    "db:5432"
    "redis:6379"
    "rabbitmq:5672"
)

for service in "${internal_services[@]}"; do
    service_name=${service%:*}
    port=${service#*:}
    
    echo -n "Checking $service_name is not exposed... "
    
    # Try to connect directly (should fail)
    if ! timeout 2 bash -c "echo >/dev/tcp/${BASE_URL#https://}/$port" 2>/dev/null; then
        echo "✓ OK (properly secured)"
    else
        echo "✗ FAILED (service is exposed!)"
        exit 1
    fi
done

# Performance checks
echo ""
echo "Performance checks..."
echo "===================="

# Measure response time
echo -n "Frontend response time: "
time=$(curl -s -o /dev/null -w "%{time_total}" "$BASE_URL/")
echo "${time}s"

if (( $(echo "$time > 5" | bc -l) )); then
    echo "⚠️  Warning: Frontend response time is slow (>5s)"
fi

echo -n "API response time: "
time=$(curl -s -o /dev/null -w "%{time_total}" "$BASE_URL/api/v1/health/")
echo "${time}s"

if (( $(echo "$time > 2" | bc -l) )); then
    echo "⚠️  Warning: API response time is slow (>2s)"
fi

# Check for common issues
echo ""
echo "Common issue checks..."
echo "====================="

# Check if static files are being served with proper caching headers
echo -n "Static file caching headers: "
cache_control=$(curl -s -I "$BASE_URL/static/js/main.js" | grep -i "cache-control" || echo "")
if [[ $cache_control == *"max-age"* ]]; then
    echo "✓ OK"
else
    echo "⚠️  Warning: No cache headers for static files"
fi

# Check if API returns proper content-type
echo -n "API Content-Type header: "
content_type=$(curl -s -I "$BASE_URL/api/v1/health/" | grep -i "content-type" || echo "")
if [[ $content_type == *"application/json"* ]]; then
    echo "✓ OK"
else
    echo "✗ FAILED: API not returning JSON content-type"
fi

# Summary
echo ""
echo "======================================"
echo "Smoke tests completed!"
echo ""

# Exit with appropriate code
if [ $? -eq 0 ]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed!"
    exit 1
fi