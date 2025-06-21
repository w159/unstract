# Azure Deployment Guide for Unstract

## Overview

This guide provides a comprehensive approach for deploying Unstract to Azure with CI/CD workflows using GitHub Actions. The deployment strategy ensures consistent environments, automated deployments, and proper source control.

## Architecture Overview

### Azure Services Used

1. **Azure Kubernetes Service (AKS)** - Container orchestration
2. **Azure Container Registry (ACR)** - Docker image storage
3. **Azure Database for PostgreSQL** - Managed database
4. **Azure Cache for Redis** - Managed Redis cache
5. **Azure Storage Account** - Object storage (MinIO replacement)
6. **Azure Service Bus** - Message queue (RabbitMQ replacement)
7. **Azure Application Gateway** - Ingress controller
8. **Azure Key Vault** - Secrets management
9. **Azure Monitor** - Logging and monitoring

### Alternative: Azure Container Instances
For smaller deployments, Azure Container Instances with Azure Container Apps can be used instead of AKS.

## Infrastructure as Code

We'll use Terraform for infrastructure provisioning. All infrastructure code is stored in the `/infrastructure` directory.

### Directory Structure
```
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── production/
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/
│   ├── aks/
│   ├── database/
│   ├── storage/
│   ├── networking/
│   └── monitoring/
├── main.tf
├── variables.tf
└── outputs.tf
```

## CI/CD Pipeline Structure

### 1. Build Pipeline (CI)
- Triggered on PR to main/develop branches
- Builds and tests all services
- Runs SonarCloud analysis
- Creates Docker images
- Pushes to ACR

### 2. Deploy Pipeline (CD)
- Triggered on merge to main/develop
- Deploys to appropriate environment
- Runs database migrations
- Performs health checks
- Sends notifications

### 3. Infrastructure Pipeline
- Triggered on changes to /infrastructure
- Plans and applies Terraform changes
- Requires manual approval for production

## GitHub Actions Workflows

### Main CI/CD Workflow Structure
```yaml
.github/
├── workflows/
│   ├── ci-build.yml          # Build and test
│   ├── cd-deploy-dev.yml     # Deploy to dev
│   ├── cd-deploy-staging.yml # Deploy to staging
│   ├── cd-deploy-prod.yml    # Deploy to production
│   ├── infrastructure.yml    # Infrastructure updates
│   └── security-scan.yml     # Security scanning
├── actions/
│   ├── build-service/        # Reusable build action
│   └── deploy-service/       # Reusable deploy action
└── dependabot.yml           # Dependency updates
```

## Security Considerations

1. **Secrets Management**
   - All secrets stored in Azure Key Vault
   - GitHub secrets reference Key Vault
   - Service Principal for authentication
   - Managed Identities for Azure services

2. **Network Security**
   - Private AKS cluster
   - Azure Firewall for egress
   - Network policies in Kubernetes
   - Private endpoints for databases

3. **Container Security**
   - Image scanning in ACR
   - Pod security policies
   - Non-root containers
   - Read-only root filesystems

## Environment Configuration

### Development Environment
- Single node AKS cluster
- Basic SKUs for databases
- Shared resources where possible
- Auto-shutdown policies

### Staging Environment
- Multi-node AKS cluster
- Production-like configuration
- Separate resource group
- Performance testing capable

### Production Environment
- Multi-zone AKS cluster
- Premium SKUs for databases
- Auto-scaling enabled
- Disaster recovery configured

## Deployment Steps

### Initial Setup

1. **Create Azure Resources**
   ```bash
   # Login to Azure
   az login
   
   # Create resource groups
   az group create --name rg-unstract-dev --location eastus
   az group create --name rg-unstract-staging --location eastus
   az group create --name rg-unstract-prod --location eastus
   
   # Create service principal for GitHub Actions
   az ad sp create-for-rbac --name "github-actions-unstract" \
     --role contributor \
     --scopes /subscriptions/{subscription-id} \
     --sdk-auth
   ```

2. **Configure GitHub Secrets**
   - AZURE_CREDENTIALS (service principal JSON)
   - AZURE_SUBSCRIPTION_ID
   - AZURE_TENANT_ID
   - ACR_LOGIN_SERVER
   - ACR_USERNAME
   - ACR_PASSWORD

3. **Initialize Terraform Backend**
   ```bash
   # Create storage account for Terraform state
   az storage account create \
     --name unstracttfstate \
     --resource-group rg-unstract-shared \
     --sku Standard_LRS
   
   # Create container
   az storage container create \
     --name tfstate \
     --account-name unstracttfstate
   ```

### Continuous Deployment

1. **Code Changes**
   - Developer creates feature branch
   - Makes changes and commits
   - Creates PR to develop/main

2. **CI Pipeline**
   - Builds all services
   - Runs tests
   - Performs security scans
   - Updates PR with results

3. **CD Pipeline**
   - Merges trigger deployment
   - Images pushed to ACR
   - Kubernetes manifests updated
   - Rolling deployment to AKS

## Monitoring and Observability

1. **Application Insights**
   - APM for all services
   - Custom metrics
   - Distributed tracing

2. **Log Analytics**
   - Centralized logging
   - Query capabilities
   - Alert rules

3. **Azure Monitor**
   - Infrastructure metrics
   - Cost monitoring
   - Performance insights

## Cost Optimization

1. **Resource Sizing**
   - Start with small SKUs
   - Monitor and scale as needed
   - Use spot instances for workers

2. **Auto-scaling**
   - HPA for pods
   - Cluster autoscaler for nodes
   - Schedule-based scaling

3. **Reserved Instances**
   - Commit to 1-3 year terms
   - Significant cost savings
   - Apply to stable workloads

## Disaster Recovery

1. **Backup Strategy**
   - Daily database backups
   - Geo-redundant storage
   - Point-in-time recovery

2. **Multi-region Setup**
   - Active-passive configuration
   - Traffic Manager for failover
   - Regular DR drills

## Migration Strategy

1. **Phase 1: Development**
   - Deploy to dev environment
   - Test all functionality
   - Performance baseline

2. **Phase 2: Staging**
   - Production data subset
   - Load testing
   - Security validation

3. **Phase 3: Production**
   - Blue-green deployment
   - Gradual traffic shift
   - Rollback plan ready

## Maintenance and Updates

1. **Regular Updates**
   - Weekly dependency updates
   - Monthly security patches
   - Quarterly Azure service updates

2. **Monitoring**
   - 24/7 alerting
   - On-call rotation
   - Incident response plan

3. **Documentation**
   - Runbooks for common issues
   - Architecture decision records
   - Change logs

## Next Steps

1. Review and approve architecture
2. Set up Azure subscription
3. Configure GitHub repository
4. Implement infrastructure code
5. Create CI/CD pipelines
6. Deploy to development
7. Validate and iterate