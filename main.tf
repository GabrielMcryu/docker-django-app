# =============================================================================
# Terraform Configuration – Django on AKS with Azure PostgreSQL & Redis
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  # ── Remote State Backend (Azure Blob Storage) ──────────────────────────────
  # Before first `terraform init` you must create the storage account:
  #   az group create -n tfstate-rg -l eastus
  #   az storage account create -n <unique_name> -g tfstate-rg -l eastus --sku Standard_LRS
  #   az storage container create -n tfstate --account-name <unique_name>
  backend "azurerm" {
    resource_group_name  = "devops-tf-rg"
    storage_account_name = "gabrielmcryutfstate46264"   # <-- replace with your actual name
    container_name       = "tfstate"
    key                  = "django-aks.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}

# ── Providers ────────────────────────────────────────────────────────────────

provider "azurerm" {
  features {}
}

# The Kubernetes provider connects via the AKS cluster credentials produced by
# the aks module.  This creates an implicit dependency: Terraform will build
# the AKS cluster first, then configure this provider.
provider "kubernetes" {
  host                   = module.aks.kube_host
  client_certificate     = base64decode(module.aks.kube_client_certificate)
  client_key             = base64decode(module.aks.kube_client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_cluster_ca_certificate)
}

# ── Resource Group ───────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.location

  tags = var.tags
}

# ── Networking ───────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_network_security_group" "aks" {
  name                = "${var.project_name}-aks-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# ── Private DNS Zone for PostgreSQL ──────────────────────────────────────────

resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.project_name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# ── Azure Database for PostgreSQL (Flexible Server) ──────────────────────────

resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "${var.project_name}-pgdb"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = "16"
  administrator_login           = var.db_admin_username
  administrator_password        = var.db_admin_password
  delegated_subnet_id           = azurerm_subnet.db.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  sku_name                      = var.db_sku
  storage_mb                    = var.db_storage_mb
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false
  zone                          = "1"

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# ── Azure Cache for Redis ────────────────────────────────────────────────────

resource "azurerm_redis_cache" "main" {
  name                          = "${var.project_name}-redis"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  capacity                      = 0
  family                        = "C"
  sku_name                      = "Basic"
  non_ssl_port_enabled          = true
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true     # For simplicity; lock down in prod

  tags = var.tags
}

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

  ghcr_username = var.ghcr_username
  ghcr_token    = var.ghcr_token

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

  secret_env_vars = {
    DB_PASSWORD    = var.db_admin_password
    SECRET_KEY     = var.django_secret_key
    REDIS_PASSWORD = azurerm_redis_cache.main.primary_access_key
  }

  depends_on = [module.aks]
}