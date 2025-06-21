terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-unstract-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# AKS Module
module "aks" {
  source = "./modules/aks"
  
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  environment             = var.environment
  kubernetes_version      = var.kubernetes_version
  node_count              = var.aks_node_count
  node_size               = var.aks_node_size
  vnet_subnet_id          = module.networking.aks_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                    = var.tags
}

# Container Registry
module "acr" {
  source = "./modules/acr"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  sku                 = var.environment == "prod" ? "Premium" : "Standard"
  tags                = var.tags
}

# PostgreSQL Database
module "postgresql" {
  source = "./modules/database"
  
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  environment            = var.environment
  subnet_id              = module.networking.database_subnet_id
  sku_name               = var.postgresql_sku
  storage_mb             = var.postgresql_storage_mb
  backup_retention_days  = var.postgresql_backup_retention_days
  geo_redundant_backup   = var.environment == "prod" ? true : false
  tags                   = var.tags
}

# Redis Cache
module "redis" {
  source = "./modules/redis"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  subnet_id           = module.networking.redis_subnet_id
  sku_name            = var.redis_sku
  family              = var.redis_family
  capacity            = var.redis_capacity
  tags                = var.tags
}

# Storage Account (replaces MinIO)
module "storage" {
  source = "./modules/storage"
  
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  environment              = var.environment
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  subnet_ids               = [module.networking.storage_subnet_id]
  tags                     = var.tags
}

# Service Bus (replaces RabbitMQ)
module "servicebus" {
  source = "./modules/servicebus"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  sku                 = var.servicebus_sku
  tags                = var.tags
}

# Key Vault
module "keyvault" {
  source = "./modules/keyvault"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  tenant_id           = data.azurerm_client_config.current.tenant_id
  aks_principal_id    = module.aks.kubelet_identity_object_id
  subnet_ids          = [module.networking.keyvault_subnet_id]
  tags                = var.tags
}

# Application Gateway (Ingress)
module "app_gateway" {
  source = "./modules/app-gateway"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  subnet_id           = module.networking.app_gateway_subnet_id
  tags                = var.tags
}

# Monitoring
module "monitoring" {
  source = "./modules/monitoring"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  tags                = var.tags
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = module.aks.kube_config.0.host
  client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
  client_key             = base64decode(module.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.0.host
    client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
  }
}

# Create namespace
resource "kubernetes_namespace" "unstract" {
  metadata {
    name = "unstract-${var.environment}"
  }
}

# Store connection strings in Key Vault
resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "database-connection-string"
  value        = module.postgresql.connection_string
  key_vault_id = module.keyvault.key_vault_id
}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "redis-connection-string"
  value        = module.redis.connection_string
  key_vault_id = module.keyvault.key_vault_id
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection-string"
  value        = module.storage.connection_string
  key_vault_id = module.keyvault.key_vault_id
}

resource "azurerm_key_vault_secret" "servicebus_connection_string" {
  name         = "servicebus-connection-string"
  value        = module.servicebus.connection_string
  key_vault_id = module.keyvault.key_vault_id
}