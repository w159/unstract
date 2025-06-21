# Azure Security and Secrets Management Guide

## Overview

This guide outlines the security best practices and secrets management approach for deploying Unstract on Azure. It ensures compliance with security standards and protects sensitive data throughout the deployment lifecycle.

## Security Architecture

### 1. Network Security

#### Virtual Network Design
```
VNet (10.0.0.0/16)
├── AKS Subnet (10.0.1.0/24)
├── Database Subnet (10.0.2.0/24)
├── Redis Subnet (10.0.3.0/24)
├── Storage Subnet (10.0.4.0/24)
├── App Gateway Subnet (10.0.5.0/24)
└── Key Vault Subnet (10.0.6.0/24)
```

#### Network Security Groups (NSGs)
- Restrict traffic between subnets
- Allow only necessary ports
- Deny all by default

#### Private Endpoints
- PostgreSQL: Private endpoint in database subnet
- Redis: Private endpoint in Redis subnet
- Storage: Private endpoint in storage subnet
- Key Vault: Private endpoint in Key Vault subnet

### 2. Identity and Access Management

#### Service Principal for CI/CD
```bash
# Create service principal with minimal permissions
az ad sp create-for-rbac \
  --name "github-actions-unstract" \
  --role "Contributor" \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/rg-unstract-{env}" \
  --sdk-auth
```

#### Managed Identities
- AKS cluster uses system-assigned managed identity
- Pod-managed identities for workloads
- No passwords or keys in application code

#### RBAC Configuration
```yaml
# AKS RBAC
- AKS Admin: Full cluster access
- Developer: Namespace-level access
- ReadOnly: View-only access

# Azure RBAC
- Owner: Subscription/RG owner
- Contributor: Deploy resources
- Reader: View resources
```

### 3. Secrets Management

#### Azure Key Vault Setup

1. **Create Key Vault**
```bash
az keyvault create \
  --name "kv-unstract-${ENVIRONMENT}" \
  --resource-group "rg-unstract-${ENVIRONMENT}" \
  --location "eastus" \
  --enable-rbac-authorization
```

2. **Store Secrets**
```bash
# Database credentials
az keyvault secret set --vault-name "kv-unstract-${ENV}" \
  --name "db-password" --value "$(openssl rand -base64 32)"

# Encryption key
az keyvault secret set --vault-name "kv-unstract-${ENV}" \
  --name "encryption-key" --value "$(openssl rand -base64 32)"

# API keys
az keyvault secret set --vault-name "kv-unstract-${ENV}" \
  --name "platform-service-api-key" --value "$(openssl rand -base64 32)"
```

#### Secrets in Kubernetes

1. **Azure Key Vault Provider for Secrets Store CSI Driver**
```bash
# Install the driver
helm repo add csi-secrets-store-provider-azure \
  https://azure.github.io/secrets-store-csi-driver-provider-azure/charts

helm install csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --generate-name --namespace kube-system
```

2. **SecretProviderClass**
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "<managed-identity-client-id>"
    keyvaultName: "kv-unstract-prod"
    objects: |
      array:
        - |
          objectName: db-password
          objectType: secret
        - |
          objectName: encryption-key
          objectType: secret
    tenantId: "<tenant-id>"
```

### 4. Container Security

#### Image Security
- Base images from official sources
- Regular vulnerability scanning
- Image signing with Azure Container Registry

#### Pod Security Standards
```yaml
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

#### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-netpol
spec:
  podSelector:
    matchLabels:
      component: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          component: frontend
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          component: database
    ports:
    - protocol: TCP
      port: 5432
```

### 5. Data Protection

#### Encryption at Rest
- Azure Storage: Service-managed keys
- PostgreSQL: Transparent data encryption
- Redis: Encryption at rest enabled
- AKS: OS disk encryption

#### Encryption in Transit
- TLS 1.2+ for all communications
- Internal service mesh with mTLS (optional)
- Application Gateway with SSL termination

#### Backup and Recovery
```bash
# Database backup
az postgres flexible-server backup list \
  --resource-group "rg-unstract-prod" \
  --name "psql-unstract-prod"

# Velero for Kubernetes backup
velero install \
  --provider azure \
  --bucket velero-backup-unstract \
  --secret-file ./credentials-velero
```

### 6. Compliance and Auditing

#### Azure Policy
```json
{
  "properties": {
    "displayName": "Require HTTPS for Storage Accounts",
    "policyType": "Custom",
    "mode": "All",
    "parameters": {},
    "policyRule": {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Storage/storageAccounts"
          },
          {
            "field": "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly",
            "notEquals": "true"
          }
        ]
      },
      "then": {
        "effect": "deny"
      }
    }
  }
}
```

#### Logging and Monitoring
- Azure Monitor for infrastructure logs
- Application Insights for application telemetry
- Azure Sentinel for security monitoring
- Log Analytics for centralized logging

### 7. CI/CD Security

#### GitHub Actions Security

1. **Secrets Configuration**
```yaml
# Store in GitHub Secrets
AZURE_CREDENTIALS: Service principal JSON
ACR_USERNAME: Registry username
ACR_PASSWORD: Registry password
SONAR_TOKEN: SonarCloud token
```

2. **Environment Protection Rules**
- Required reviewers for production
- Environment secrets scoped appropriately
- Deployment protection rules

3. **Secure Workflows**
```yaml
# Use specific action versions
- uses: actions/checkout@v4

# Limit permissions
permissions:
  contents: read
  id-token: write

# Use OIDC for authentication
- uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### 8. Security Checklist

#### Pre-Deployment
- [ ] Key Vault created and configured
- [ ] Network security groups configured
- [ ] Private endpoints enabled
- [ ] RBAC roles assigned
- [ ] Secrets rotated

#### Deployment
- [ ] Images scanned for vulnerabilities
- [ ] Network policies applied
- [ ] Pod security standards enforced
- [ ] TLS certificates valid
- [ ] Ingress rules configured

#### Post-Deployment
- [ ] Security monitoring enabled
- [ ] Backup configured
- [ ] Incident response plan ready
- [ ] Security patches scheduled
- [ ] Compliance validated

### 9. Incident Response

#### Security Incident Procedure
1. **Detection**: Alert from monitoring
2. **Containment**: Isolate affected resources
3. **Investigation**: Analyze logs and metrics
4. **Remediation**: Apply fixes
5. **Recovery**: Restore services
6. **Post-Mortem**: Document lessons learned

#### Emergency Access
```bash
# Break-glass account setup
az ad user create \
  --display-name "Emergency Admin" \
  --user-principal-name "emergency@domain.com" \
  --password "ComplexPassword123!" \
  --force-change-password-next-sign-in false

# Assign Owner role
az role assignment create \
  --assignee "emergency@domain.com" \
  --role "Owner" \
  --scope "/subscriptions/{subscription-id}"
```

### 10. Security Tools Integration

#### Azure Security Center
- Enable for all subscriptions
- Configure security policies
- Review recommendations weekly

#### Azure Defender
- Enable for AKS
- Enable for Container Registry
- Enable for Key Vault
- Enable for Storage

#### Third-Party Tools
- SonarCloud for code analysis
- Trivy for container scanning
- OWASP ZAP for web app scanning
- Falco for runtime security

## Secrets Rotation

### Automated Rotation Script
```bash
#!/bin/bash
# rotate-secrets.sh

# Rotate database password
NEW_DB_PASSWORD=$(openssl rand -base64 32)
az keyvault secret set \
  --vault-name "kv-unstract-prod" \
  --name "db-password" \
  --value "$NEW_DB_PASSWORD"

# Update PostgreSQL
az postgres flexible-server update \
  --resource-group "rg-unstract-prod" \
  --name "psql-unstract-prod" \
  --admin-password "$NEW_DB_PASSWORD"

# Restart pods to pick up new secrets
kubectl rollout restart deployment/backend -n unstract-prod
```

### Rotation Schedule
- **API Keys**: Every 90 days
- **Database Passwords**: Every 60 days
- **Certificates**: 30 days before expiry
- **Service Principal**: Yearly

## Conclusion

This security guide provides comprehensive protection for Unstract deployed on Azure. Regular reviews and updates of security policies ensure continued protection against evolving threats.