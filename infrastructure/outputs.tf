output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.acr.login_server
}

output "acr_admin_username" {
  description = "ACR admin username"
  value       = module.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "ACR admin password"
  value       = module.acr.admin_password
  sensitive   = true
}

output "postgresql_server_name" {
  description = "PostgreSQL server name"
  value       = module.postgresql.server_name
}

output "postgresql_fqdn" {
  description = "PostgreSQL FQDN"
  value       = module.postgresql.fqdn
}

output "redis_hostname" {
  description = "Redis hostname"
  value       = module.redis.hostname
}

output "redis_port" {
  description = "Redis port"
  value       = module.redis.port
}

output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage.storage_account_name
}

output "storage_primary_endpoint" {
  description = "Storage primary endpoint"
  value       = module.storage.primary_blob_endpoint
}

output "servicebus_namespace" {
  description = "Service Bus namespace"
  value       = module.servicebus.namespace_name
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.keyvault.key_vault_uri
}

output "app_gateway_public_ip" {
  description = "Application Gateway public IP"
  value       = module.app_gateway.public_ip_address
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.monitoring.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.monitoring.connection_string
  sensitive   = true
}