# Comprehensive CI/CD Plan for Unstract Multi-Container Application

## Executive Summary

This document provides a comprehensive CI/CD plan for the Unstract multi-container application, including recommendations for Azure services, deployment strategies, and solutions for performance issues.

## 1. Application Architecture Overview

The Unstract application consists of:

### Core Services:
- **Backend** (Django + Celery workers)
- **Frontend** (React with Nginx)
- **Platform Service** (Node.js)
- **Prompt Service** (Platform: linux/amd64)
- **X2Text Service**
- **Runner Service**

### Supporting Services:
- **PostgreSQL** (with pgvector extension)
- **Redis** (cache and message broker)
- **RabbitMQ** (message queue)
- **MinIO** (S3-compatible object storage)
- **Qdrant** (vector database)
- **Traefik** (reverse proxy)

### Worker Services:
- Default Celery worker
- Logging worker
- File processing worker
- File processing callback worker
- Celery Beat (scheduler)

## 2. Azure Service Comparison and Recommendations

### Comparison Matrix

| Service | Best For | Multi-Container Support | Cost Model | Scaling | Complexity |
|---------|----------|------------------------|------------|---------|------------|
| **AKS** | Complex production workloads | Full Kubernetes orchestration | Pay for VMs | Auto-scaling | High |
| **Container Apps** | Microservices with variable load | Limited docker-compose | Pay per second, scale-to-zero | Auto-scaling | Medium |
| **Container Instances** | Short-lived tasks | Container groups | Pay per second | Manual only | Low |
| **App Service** | Traditional web apps | Docker-compose support | Fixed hourly | Within plan | Low |

### **Recommendation: Azure Container Apps**

For the Unstract application, **Azure Container Apps** is recommended because:

1. **Cost-effective**: Scale-to-zero capability reduces costs during low usage
2. **Microservices-friendly**: Native support for multiple containers
3. **Built-in features**: Includes ingress, scaling, and monitoring
4. **Managed infrastructure**: No Kubernetes management overhead
5. **KEDA integration**: Event-driven scaling for queue workers

### Migration Strategy from Docker Compose

Since Container Apps has limited docker-compose support, we'll need to:
1. Deploy each service as a separate container app
2. Use Container Apps environments for networking
3. Configure service-to-service communication
4. Set up ingress rules for public-facing services

## 3. Persistent Storage Strategy

### Database Services (Production)

**DO NOT run databases in containers for production!**

1. **PostgreSQL**: Use **Azure Database for PostgreSQL**
   - Fully managed service
   - Automatic backups
   - High availability options
   - pgvector extension support

2. **Redis**: Use **Azure Cache for Redis**
   - Managed service with persistence options
   - RDB and AOF persistence formats
   - Premium tier for production workloads

3. **File Storage**: Use **Azure Storage**
   - Blob storage for MinIO replacement
   - File shares for shared storage needs
   - Azure Container Storage for persistent volumes

### Development/Testing

For development, you can continue using containerized databases with:
- Azure Files for PostgreSQL data (note: performance limitations)
- Managed disks for better performance
- Regular backup strategies

## 4. CI/CD Pipeline Design

### GitHub Actions Workflow Structure

```yaml
name: Build and Deploy Unstract

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: acrunstract21468.azurecr.io
  VERSION: ${{ github.sha }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    strategy:
      matrix:
        service:
          - name: backend
            context: ./backend
            dockerfile: ./docker/dockerfiles/backend.Dockerfile
          - name: frontend
            context: ./frontend
            dockerfile: ./docker/dockerfiles/frontend.Dockerfile
          - name: platform-service
            context: ./platform-service
            dockerfile: ./docker/dockerfiles/platform.Dockerfile
          - name: prompt-service
            context: ./prompt-service
            dockerfile: ./docker/dockerfiles/prompt.Dockerfile
          - name: x2text-service
            context: ./x2text-service
            dockerfile: ./docker/dockerfiles/x2text.Dockerfile
          - name: runner
            context: ./runner
            dockerfile: ./docker/dockerfiles/runner.Dockerfile
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Build and push to ACR
        run: |
          az acr build \
            --registry ${{ env.REGISTRY }} \
            --image unstract/${{ matrix.service.name }}:${{ env.VERSION }} \
            --image unstract/${{ matrix.service.name }}:latest \
            --file ${{ matrix.service.dockerfile }} \
            ${{ matrix.service.context }}

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Deploy to Container Apps
        run: |
          # Deploy each service to Container Apps
          # Implementation details below
```

### Deployment Script for Container Apps

```bash
#!/bin/bash
# deploy-to-container-apps.sh

RESOURCE_GROUP="unstract-rg"
ENVIRONMENT="unstract-env"
LOCATION="eastus"

# Create Container Apps environment if not exists
az containerapp env create \
  --name $ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Deploy Backend
az containerapp create \
  --name unstract-backend \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $REGISTRY/unstract/backend:$VERSION \
  --target-port 8000 \
  --ingress 'internal' \
  --min-replicas 1 \
  --max-replicas 10 \
  --cpu 1 \
  --memory 2Gi \
  --env-vars "ENVIRONMENT=production" \
             "DJANGO_SETTINGS_MODULE=backend.settings.production"

# Deploy Frontend
az containerapp create \
  --name unstract-frontend \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $REGISTRY/unstract/frontend:$VERSION \
  --target-port 80 \
  --ingress 'external' \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 0.5 \
  --memory 1Gi

# Deploy Workers with KEDA scaling
az containerapp create \
  --name unstract-worker \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $REGISTRY/unstract/backend:$VERSION \
  --min-replicas 0 \
  --max-replicas 20 \
  --scale-rule-name queue-based \
  --scale-rule-type rabbitmq \
  --scale-rule-metadata "queueName=celery" \
                        "queueLength=10"
```

## 5. Secrets Management Strategy

### OIDC Authentication Setup

1. **Create Azure AD Application**:
```bash
az ad app create --display-name "unstract-github-actions"
az ad sp create --id <app-id>
```

2. **Configure Federated Credentials**:
```json
{
  "name": "unstract-github-deploy",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:yourorg/unstract:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}
```

3. **GitHub Secrets Required**:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

### Application Secrets Management

Use Azure Key Vault for application secrets:

```bash
# Create Key Vault
az keyvault create \
  --name unstract-kv \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Add secrets
az keyvault secret set \
  --vault-name unstract-kv \
  --name "django-secret-key" \
  --value "<your-secret>"

# Grant access to Container Apps
az containerapp identity assign \
  --name unstract-backend \
  --resource-group $RESOURCE_GROUP \
  --system-assigned

az keyvault set-policy \
  --name unstract-kv \
  --object-id <identity-object-id> \
  --secret-permissions get list
```

## 6. Performance Optimization

### Addressing "Please wait while we prepare your session" Issues

The slow loading is likely due to:

1. **Cold Starts**: Container Apps scale to zero, causing initialization delays
2. **Large Container Images**: The application containers are quite large
3. **Sequential Service Startup**: Services waiting for dependencies

### Solutions:

1. **Maintain Minimum Replicas**:
```bash
--min-replicas 1  # For critical services
```

2. **Optimize Container Images**:
```dockerfile
# Use multi-stage builds
FROM python:3.12-slim AS builder
# Build dependencies
FROM python:3.12-slim AS runtime
# Copy only necessary files
```

3. **Implement Health Checks**:
```yaml
healthCheck:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10
```

4. **Use Container Registry in Same Region**:
- Deploy ACR in the same region as Container Apps
- Use Premium tier for geo-replication if needed

5. **Pre-warm Critical Services**:
```bash
# Add startup probes with longer timeouts
az containerapp update \
  --name unstract-backend \
  --startup-probe-path "/startup" \
  --startup-probe-period 10 \
  --startup-probe-timeout 300
```

## 7. Cost Analysis and Optimization

### Estimated Monthly Costs (USD)

#### Container Apps Option:
- **Compute**: ~$200-400 (based on usage)
  - vCPU: $0.000024/vCPU-second
  - Memory: $0.0000025/GiB-second
- **Managed Services**:
  - PostgreSQL: $100-200 (Basic tier)
  - Redis: $50-100 (Basic tier)
  - Storage: $50-100
- **Total**: ~$400-800/month

#### AKS Option:
- **Cluster**: $0 (management free)
- **VMs**: $500-1000 (3-5 nodes)
- **Managed Services**: Same as above
- **Total**: ~$750-1400/month

### Cost Optimization Strategies:

1. **Use Dev/Test Pricing** where applicable
2. **Implement aggressive scaling policies**
3. **Use spot instances for non-critical workloads**
4. **Monitor and optimize resource allocation**
5. **Consider reserved instances for predictable workloads**

## 8. Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Set up Azure resources (Resource Group, ACR, Key Vault)
- [ ] Configure OIDC authentication
- [ ] Create base GitHub Actions workflow
- [ ] Set up managed databases (PostgreSQL, Redis)

### Phase 2: Migration (Week 3-4)
- [ ] Containerize and optimize images
- [ ] Deploy core services to Container Apps
- [ ] Configure networking and service discovery
- [ ] Implement health checks and monitoring

### Phase 3: Optimization (Week 5-6)
- [ ] Performance tuning and testing
- [ ] Implement auto-scaling rules
- [ ] Set up monitoring and alerting
- [ ] Document deployment procedures

### Phase 4: Production (Week 7-8)
- [ ] Final testing and validation
- [ ] Create disaster recovery plan
- [ ] Train team on new deployment process
- [ ] Go-live and monitoring

## 9. Monitoring and Observability

### Azure Monitor Integration
```bash
# Enable Container Apps monitoring
az monitor app-insights component create \
  --app unstract-insights \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP

# Connect to Container Apps
az containerapp update \
  --name unstract-backend \
  --resource-group $RESOURCE_GROUP \
  --dapr-app-id unstract-backend \
  --dapr-app-port 8000 \
  --dapr-instrumentation-key <instrumentation-key>
```

### Key Metrics to Monitor:
- Response times
- Error rates
- Resource utilization
- Scaling events
- Cold start frequency

## 10. Disaster Recovery

### Backup Strategy:
1. **Database**: Automated backups with point-in-time restore
2. **Container Images**: Geo-replicated registry
3. **Configuration**: Version controlled in Git
4. **Secrets**: Key Vault with soft-delete enabled

### Recovery Procedures:
1. Document RTO/RPO requirements
2. Test failover procedures regularly
3. Maintain runbooks for common scenarios
4. Implement automated health checks

## Conclusion

This CI/CD plan provides a comprehensive approach to deploying the Unstract multi-container application on Azure. By using Azure Container Apps with managed services, you'll achieve:

- Reduced operational overhead
- Better scalability
- Improved reliability
- Cost optimization through scale-to-zero
- Enhanced security with OIDC and Key Vault

The phased implementation approach ensures a smooth migration with minimal disruption to existing workflows.