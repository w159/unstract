# Performance Optimization Guide for Unstract

## Diagnosing "Please wait while we prepare your session" Issue

The slow loading screen indicates container initialization delays. Here's a comprehensive guide to diagnose and fix performance issues.

## Root Causes Analysis

### 1. Cold Start Issues
When Azure Container Apps scale to zero, the next request triggers:
- Container image pull from registry
- Container initialization
- Application startup
- Service discovery and health checks

**Impact**: 15-60 seconds delay on first request

### 2. Large Container Images
Current image sizes are contributing to slow pulls:
```bash
# Check image sizes
docker images | grep unstract
# unstract/backend        1.2GB
# unstract/frontend       450MB
# unstract/platform       380MB
```

### 3. Sequential Service Dependencies
Services wait for dependencies, creating a cascade effect:
```
Frontend → Backend → Database/Redis/RabbitMQ → Platform/Prompt/X2Text Services
```

## Optimization Strategies

### 1. Image Size Optimization

#### Multi-Stage Builds Enhancement
```dockerfile
# backend.Dockerfile - Optimized
FROM python:3.12-slim AS builder

# Install only build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Build wheels
COPY pyproject.toml uv.lock /app/
WORKDIR /app
RUN pip install uv && \
    uv pip compile --python-version 3.12 pyproject.toml -o requirements.txt && \
    uv pip wheel -r requirements.txt -w /wheels

# Runtime stage
FROM python:3.12-slim

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# Copy wheels and install
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/*.whl && rm -rf /wheels

# Copy application
COPY backend/ /app/
WORKDIR /app

EXPOSE 8000
CMD ["gunicorn", "backend.wsgi:application"]
```

#### Frontend Optimization
```dockerfile
# frontend.Dockerfile - Optimized
FROM node:16-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# Use distroless for minimal runtime
FROM gcr.io/distroless/nodejs16-debian11
COPY --from=builder /app/build /app
COPY --from=builder /app/node_modules /node_modules
EXPOSE 3000
CMD ["/app/server.js"]
```

### 2. Container Apps Configuration

#### Maintain Minimum Replicas
```bash
# Critical services should never scale to zero
az containerapp update \
  --name unstract-backend-production \
  --resource-group unstract-prod-rg \
  --min-replicas 2 \
  --max-replicas 20

az containerapp update \
  --name unstract-frontend-production \
  --resource-group unstract-prod-rg \
  --min-replicas 2 \
  --max-replicas 10
```

#### Configure Readiness Probes
```yaml
# In Container Apps configuration
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 3

livenessProbe:
  httpGet:
    path: /health/live
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3
```

### 3. Application-Level Optimizations

#### Implement Health Check Endpoints
```python
# backend/health/views.py
from django.http import JsonResponse
from django.core.cache import cache
from django.db import connection

def readiness_check(request):
    """Check if the app is ready to serve requests"""
    checks = {
        'database': check_database(),
        'cache': check_cache(),
        'services': check_services()
    }
    
    is_ready = all(checks.values())
    status_code = 200 if is_ready else 503
    
    return JsonResponse({
        'ready': is_ready,
        'checks': checks
    }, status=status_code)

def liveness_check(request):
    """Simple check to see if app is alive"""
    return JsonResponse({'alive': True})

def check_database():
    try:
        connection.ensure_connection()
        return True
    except:
        return False

def check_cache():
    try:
        cache.set('health_check', 'ok', 1)
        return cache.get('health_check') == 'ok'
    except:
        return False

def check_services():
    # Check if required services are accessible
    services = {
        'platform': 'http://platform-service:3001/health',
        'prompt': 'http://prompt-service:3003/health',
        'x2text': 'http://x2text-service:3004/health'
    }
    
    for service, url in services.items():
        try:
            response = requests.get(url, timeout=2)
            if response.status_code != 200:
                return False
        except:
            return False
    
    return True
```

#### Parallel Service Initialization
```javascript
// frontend/src/App.js
async function initializeApp() {
  // Initialize services in parallel instead of sequentially
  const initPromises = [
    initializeAuth(),
    loadConfiguration(),
    checkBackendHealth(),
    loadUserPreferences()
  ];
  
  try {
    await Promise.all(initPromises);
    setAppReady(true);
  } catch (error) {
    console.error('App initialization failed:', error);
    setInitError(error);
  }
}
```

### 4. Azure Infrastructure Optimizations

#### Use Premium Container Registry
```bash
# Upgrade to Premium for better performance and geo-replication
az acr update \
  --name acrunstract21468 \
  --sku Premium

# Enable geo-replication
az acr replication create \
  --registry acrunstract21468 \
  --location westus
```

#### Configure Container Apps Environment
```bash
# Create environment with performance optimizations
az containerapp env create \
  --name unstract-prod-env \
  --resource-group unstract-prod-rg \
  --location eastus \
  --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_ID \
  --zone-redundant

# Enable Dapr for service-to-service communication
az containerapp env dapr-component create \
  --name statestore \
  --environment unstract-prod-env \
  --resource-group unstract-prod-rg \
  --dapr-component-name statestore \
  --yaml dapr-redis-state.yaml
```

### 5. Monitoring and Diagnostics

#### Enable Application Insights
```python
# backend/settings/production.py
APPLICATIONINSIGHTS = {
    'ikey': os.environ.get('APPINSIGHTS_INSTRUMENTATIONKEY'),
    'endpoint': 'https://eastus-0.in.applicationinsights.azure.com/'
}

# Add custom telemetry
from applicationinsights import TelemetryClient
tc = TelemetryClient(APPLICATIONINSIGHTS['ikey'])

def track_startup_time():
    start_time = time.time()
    # ... initialization code ...
    duration = time.time() - start_time
    tc.track_metric('app_startup_time', duration)
    tc.flush()
```

#### Container Apps Metrics
```bash
# Monitor container startup times
az monitor metrics list \
  --resource-type "Microsoft.App/containerApps" \
  --resource unstract-backend-production \
  --resource-group unstract-prod-rg \
  --metric "ContainerAppStartupTime" \
  --aggregation Average \
  --interval PT1M
```

### 6. Quick Wins Checklist

1. **Immediate Actions** (1-2 hours):
   - [ ] Increase minimum replicas to 1 for critical services
   - [ ] Enable container registry caching
   - [ ] Add health check endpoints

2. **Short-term** (1-2 days):
   - [ ] Optimize Dockerfiles with multi-stage builds
   - [ ] Implement parallel initialization
   - [ ] Configure readiness/liveness probes

3. **Medium-term** (1 week):
   - [ ] Migrate to managed databases (PostgreSQL, Redis)
   - [ ] Implement Dapr for service communication
   - [ ] Set up comprehensive monitoring

### 7. Testing Performance Improvements

```bash
# Measure cold start time
time curl -w "@curl-format.txt" -o /dev/null -s https://unstract.example.com

# Load test to ensure warm containers
hey -z 30s -c 10 https://unstract.example.com/api/v1/health/

# Monitor response times
while true; do
  curl -w "Time: %{time_total}s\n" -o /dev/null -s https://unstract.example.com
  sleep 5
done
```

### 8. Expected Results

After implementing these optimizations:
- Cold start: 60s → 15s
- Warm start: 5s → <1s
- Image pull time: 30s → 10s
- Overall session prep: 90s → 20s

## Troubleshooting Commands

```bash
# Check container logs
az containerapp logs show \
  --name unstract-backend-production \
  --resource-group unstract-prod-rg \
  --follow

# View revision status
az containerapp revision list \
  --name unstract-backend-production \
  --resource-group unstract-prod-rg

# Check scaling history
az monitor autoscale history list \
  --resource-group unstract-prod-rg \
  --name unstract-backend-autoscale

# Analyze image layers
docker history unstract/backend:latest --no-trunc
```

## Performance Monitoring Dashboard

Create an Azure Dashboard with these key metrics:
1. Container startup time (P50, P95, P99)
2. Request latency by endpoint
3. Container replica count over time
4. Image pull duration
5. Health check success rate
6. Cold start frequency

This comprehensive optimization approach should significantly reduce the "Please wait while we prepare your session" duration and improve overall application performance.