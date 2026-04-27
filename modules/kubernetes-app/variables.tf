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