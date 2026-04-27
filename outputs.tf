# =============================================================================
# Outputs
# =============================================================================

output "resource_group_name" {
  description = "Name of the Azure resource group."
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster API server."
  value       = module.aks.cluster_fqdn
}

output "postgresql_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_database" {
  description = "Name of the application database."
  value       = azurerm_postgresql_flexible_server_database.app.name
}

output "redis_hostname" {
  description = "Hostname of Azure Cache for Redis."
  value       = azurerm_redis_cache.main.hostname
}

output "redis_primary_key" {
  description = "Primary access key for Redis."
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "db_admin_password" {
  description = "Database admin password (sensitive)."
  value       = var.db_admin_password
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Run this to configure kubectl locally."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}
