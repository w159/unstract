resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-unstract-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "unstract-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.node_size
    os_disk_size_gb     = 100
    vnet_subnet_id      = var.vnet_subnet_id
    enable_auto_scaling = true
    min_count           = var.node_count
    max_count           = var.node_count * 2
    
    node_labels = {
      "environment" = var.environment
    }
    
    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    load_balancer_sku  = "standard"
    service_cidr       = "10.1.0.0/16"
    dns_service_ip     = "10.1.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
    
    azure_policy {
      enabled = true
    }
    
    ingress_application_gateway {
      enabled    = true
      gateway_id = var.app_gateway_id
    }
  }

  role_based_access_control {
    enabled = true
    
    azure_active_directory {
      managed                = true
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  tags = var.tags
}

# Additional node pool for workloads
resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.workload_node_size
  node_count            = var.workload_node_count
  vnet_subnet_id        = var.vnet_subnet_id
  enable_auto_scaling   = true
  min_count             = var.workload_node_count
  max_count             = var.workload_node_count * 3
  
  node_labels = {
    "workload" = "unstract"
    "environment" = var.environment
  }
  
  node_taints = [
    "workload=unstract:NoSchedule"
  ]
  
  tags = var.tags
}

# Grant ACR pull permissions to AKS
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}