# ── AKS Module ───────────────────────────────────────────────────────────────

module "aks" {
  source = "./modules/aks"

  project_name        = var.project_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.aks.id
  node_count          = var.aks_node_count
  node_vm_size        = var.aks_node_vm_size
  tags                = var.tags
}

# ── Kubernetes Application Module ────────────────────────────────────────────

module "kubernetes_app" {
  source = "./modules/kubernetes-app"

  app_name        = var.project_name
  namespace       = var.k8s_namespace
  container_image = var.container_image
  replicas        = var.app_replicas

  # GHCR image-pull credentials
  ghcr_username = var.ghcr_username
  ghcr_token    = var.ghcr_token

  # Environment variables injected into the Django container
  env_vars = {
    DJANGO_SETTINGS_MODULE = var.django_settings_module
    ALLOWED_HOSTS          = "*"
    DB_HOST                = azurerm_postgresql_flexible_server.main.fqdn
    DB_PORT                = "5432"
    DB_NAME                = var.db_name
    DB_USER                = var.db_admin_username
    REDIS_HOST             = azurerm_redis_cache.main.hostname
    REDIS_PORT             = tostring(azurerm_redis_cache.main.port)
  }

  # Sensitive values go into a Kubernetes Secret
  secret_env_vars = {
    DB_PASSWORD    = var.db_admin_password
    SECRET_KEY     = var.django_secret_key
    REDIS_PASSWORD = azurerm_redis_cache.main.primary_access_key
  }

  depends_on = [module.aks]
}
