variable "app_name" {
  type = string
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "container_image" {
  type = string
}

variable "replicas" {
  type    = number
  default = 2
}

variable "env_vars" {
  description = "Non-sensitive environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Sensitive environment variables – stored in a Kubernetes Secret."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "ghcr_username" {
  description = "GitHub username for GHCR image pull."
  type        = string
}

variable "ghcr_token" {
  description = "GitHub PAT with read:packages scope for GHCR image pull."
  type        = string
  sensitive   = true
}
