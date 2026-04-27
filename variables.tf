# =============================================================================
# Input Variables
# =============================================================================

# ── General ──────────────────────────────────────────────────────────────────

variable "project_name" {
  description = "Prefix used for all resource names."
  type        = string
  default     = "django-aks"
}

variable "location" {
  description = "Azure region to deploy resources into."
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    Project     = "django-aks"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# ── AKS ──────────────────────────────────────────────────────────────────────

variable "aks_node_count" {
  description = "Number of nodes in the default AKS node pool."
  type        = number
  default     = 2
}

variable "aks_node_vm_size" {
  description = "VM size for the AKS node pool."
  type        = string
  default     = "Standard_B2s"
}

# ── Kubernetes / Application ─────────────────────────────────────────────────

variable "k8s_namespace" {
  description = "Kubernetes namespace for the Django application."
  type        = string
  default     = "django-app"
}

variable "container_image" {
  description = "Full GHCR image reference (ghcr.io/owner/repo:tag)."
  type        = string
  default     = "ghcr.io/yourusername/django-app:latest"  # update with your GitHub username
}

variable "app_replicas" {
  description = "Number of pod replicas for the Django deployment."
  type        = number
  default     = 2
}

variable "django_settings_module" {
  description = "DJANGO_SETTINGS_MODULE env var value."
  type        = string
  default     = "config.settings.production"
}

variable "django_secret_key" {
  description = "Django SECRET_KEY – provide via TF_VAR_django_secret_key."
  type        = string
  sensitive   = true
}

# ── GHCR (GitHub Container Registry) ────────────────────────────────────────

variable "ghcr_username" {
  description = "GitHub username for pulling images from GHCR."
  type        = string
}

variable "ghcr_token" {
  description = "GitHub PAT or GITHUB_TOKEN with read:packages scope – provide via TF_VAR_ghcr_token."
  type        = string
  sensitive   = true
}

# ── Database ─────────────────────────────────────────────────────────────────

variable "db_admin_username" {
  description = "Admin username for the PostgreSQL Flexible Server."
  type        = string
  default     = "pgadmin"
}

variable "db_admin_password" {
  description = "Admin password for the PostgreSQL Flexible Server – provide via TF_VAR_db_admin_password."
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the application database."
  type        = string
  default     = "djangodb"
}

variable "db_sku" {
  description = "SKU for the PostgreSQL Flexible Server."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  description = "Storage allocated to PostgreSQL (MB)."
  type        = number
  default     = 32768
}
