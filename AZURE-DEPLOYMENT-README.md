# Azure Deployment for Unstract - Complete Guide

## 📋 Overview

This repository now includes a complete Azure deployment solution for Unstract, featuring:
- **Infrastructure as Code** using Terraform
- **CI/CD Pipelines** with GitHub Actions
- **Security Best Practices** with Azure Key Vault
- **Automated Deployments** to AKS
- **Multi-environment Support** (dev, staging, production)

## 🏗️ Architecture

### Azure Services Used
- **Azure Kubernetes Service (AKS)** - Container orchestration
- **Azure Container Registry (ACR)** - Docker images
- **Azure Database for PostgreSQL** - Managed database
- **Azure Cache for Redis** - Caching layer
- **Azure Storage Account** - Object storage
- **Azure Service Bus** - Message queue
- **Azure Key Vault** - Secrets management
- **Azure Monitor** - Logging and monitoring

### Repository Structure
```
unstract/
├── .github/workflows/        # CI/CD pipelines
│   ├── ci-build.yml         # Build and test
│   ├── cd-deploy.yml        # Deployment workflow
│   ├── cd-deploy-dev.yml    # Dev deployment
│   └── cd-deploy-prod.yml   # Production deployment
├── infrastructure/          # Terraform IaC
│   ├── main.tf             # Main configuration
│   ├── variables.tf        # Variable definitions
│   ├── outputs.tf          # Output values
│   └── modules/            # Terraform modules
├── k8s/                    # Kubernetes manifests
│   ├── manifests/          # K8s YAML files
│   └── environments/       # Environment configs
├── scripts/                # Deployment scripts
│   └── azure/             # Azure-specific scripts
└── docs/                  # Documentation
```

## 🚀 Quick Start

### Prerequisites
1. Azure subscription
2. GitHub repository with Actions enabled
3. Azure CLI installed
4. Terraform installed
5. kubectl installed

### Initial Setup

1. **Clone the repository**
```bash
git clone https://github.com/your-org/unstract.git
cd unstract
```

2. **Login to Azure**
```bash
az login
az account set --subscription "Your Subscription Name"
```

3. **Create Service Principal**
```bash
# Create service principal for GitHub Actions
az ad sp create-for-rbac \
  --name "github-actions-unstract" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --sdk-auth > github-sp.json
```

4. **Configure GitHub Secrets**
Add these secrets to your GitHub repository:
- `AZURE_CREDENTIALS`: Contents of github-sp.json
- `AZURE_SUBSCRIPTION_ID`: Your subscription ID
- `AZURE_TENANT_ID`: Your tenant ID
- `SONAR_TOKEN`: SonarCloud token (optional)

5. **Initialize Infrastructure**
```bash
cd infrastructure

# Initialize Terraform
terraform init

# Create workspace for dev
terraform workspace new dev

# Plan infrastructure
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="environments/dev/terraform.tfvars"
```

## 📦 Deployment Process

### Automated Deployment (Recommended)

1. **Development Deployment**
   - Push to `develop` branch
   - CI pipeline builds and tests
   - Automatically deploys to dev environment

2. **Production Deployment**
   - Push to `main` branch
   - Deploys to staging first
   - Requires manual approval
   - Then deploys to production

### Manual Deployment

```bash
# Deploy to specific environment
./scripts/azure/deploy-to-aks.sh dev v1.0.0

# Check deployment status
kubectl get pods -n unstract-dev

# View logs
kubectl logs -n unstract-dev -l component=backend
```

## 🔐 Security Configuration

### Key Vault Setup
All secrets are stored in Azure Key Vault:
```bash
# Set database password
az keyvault secret set \
  --vault-name "kv-unstract-dev" \
  --name "db-password" \
  --value "your-secure-password"

# Set encryption key
az keyvault secret set \
  --vault-name "kv-unstract-dev" \
  --name "encryption-key" \
  --value "$(openssl rand -base64 32)"
```

### Important Secrets
- `db-password`: PostgreSQL password
- `redis-password`: Redis password
- `encryption-key`: Data encryption key
- `platform-service-api-key`: Internal API key
- `storage-connection-string`: Azure Storage connection

## 🔄 CI/CD Workflows

### Build Pipeline (CI)
Triggered on: Pull requests to main/develop
- Runs tests for all services
- Builds Docker images
- Runs security scans
- Updates PR with status

### Deploy Pipeline (CD)
Triggered on: Push to main/develop
- Deploys to appropriate environment
- Runs database migrations
- Performs health checks
- Sends notifications

## 📊 Monitoring

### Application Monitoring
```bash
# View application logs
kubectl logs -f deployment/backend -n unstract-dev

# Check metrics
az monitor metrics list \
  --resource "/subscriptions/.../resourceGroups/rg-unstract-dev/providers/Microsoft.ContainerService/managedClusters/aks-unstract-dev" \
  --metric "node_cpu_usage_percentage"
```

### Alerts Configuration
Alerts are configured for:
- High CPU/Memory usage
- Failed deployments
- Application errors
- Database connection issues

## 🛠️ Maintenance

### Update Infrastructure
```bash
cd infrastructure
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### Update Application
```bash
# Update image tag in deployment
kubectl set image deployment/backend \
  backend=acrunstractdev.azurecr.io/unstract/backend:v1.1.0 \
  -n unstract-dev
```

### Backup and Restore
```bash
# Backup database
az postgres flexible-server backup create \
  --resource-group rg-unstract-prod \
  --server-name psql-unstract-prod \
  --backup-name manual-backup-$(date +%Y%m%d)

# Restore database
az postgres flexible-server restore \
  --source-server psql-unstract-prod \
  --restore-point-in-time "2024-01-15T13:00:00Z" \
  --name psql-unstract-prod-restored
```

## 🚨 Troubleshooting

### Common Issues

1. **Pod not starting**
```bash
kubectl describe pod <pod-name> -n unstract-dev
kubectl logs <pod-name> -n unstract-dev
```

2. **Database connection issues**
```bash
# Check database status
az postgres flexible-server show \
  --resource-group rg-unstract-dev \
  --name psql-unstract-dev

# Test connection
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql -h <db-host> -U <db-user> -d <db-name>
```

3. **Image pull errors**
```bash
# Check ACR credentials
kubectl get secret acr-secret -n unstract-dev -o yaml

# Re-create secret
./scripts/azure/deploy-to-aks.sh dev latest
```

## 📚 Additional Documentation

- [Azure Deployment Guide](AZURE-DEPLOYMENT-GUIDE.md) - Detailed deployment instructions
- [Security Guide](AZURE-SECURITY-GUIDE.md) - Security best practices
- [Original README](README.md) - Application documentation

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section
2. Review Azure Monitor logs
3. Open an issue in GitHub
4. Contact the DevOps team

## 📄 License

This deployment configuration follows the same license as the Unstract project.