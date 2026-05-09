# =============================================================================
# Module: Kubernetes Application (Django Deployment + Service)
# =============================================================================

# ── Namespace ────────────────────────────────────────────────────────────────

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace
  }
}

# ── Secret for sensitive env vars ────────────────────────────────────────────

resource "kubernetes_secret" "app" {
  metadata {
    name      = "${var.app_name}-secret"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = var.secret_env_vars
}

# ── GHCR Image-Pull Secret ──────────────────────────────────────────────────

resource "kubernetes_secret" "ghcr" {
  metadata {
    name      = "ghcr-pull-secret"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          auth = base64encode("${var.ghcr_username}:${var.ghcr_token}")
        }
      }
    })
  }
}

# ── Deployment ───────────────────────────────────────────────────────────────

resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.ghcr.metadata[0].name
        }

        container {
          name  = var.app_name
          image = var.container_image

          port {
            container_port = 8000
          }

          dynamic "env" {
            for_each = var.env_vars
            content {
              name  = env.key
              value = env.value
            }
          }

          dynamic "env" {
            # Iterate the keys only — values stay sensitive and come from the K8s secret.
            for_each = nonsensitive(toset(keys(var.secret_env_vars)))
            content {
              name = env.value
              value_from {
                secret_key_ref {
                  name = kubernetes_secret.app.metadata[0].name
                  key  = env.value
                }
              }
            }
          }

          command = ["/bin/sh", "-c"]
          args = [
            "uv run manage.py migrate --noinput && uv run gunicorn django_redis_postgres_app.wsgi:application --bind 0.0.0.0:8000 --workers 3"
          ]

          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health/"
              port = 8000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health/"
              port = 8000
            }
            initial_delay_seconds = 15
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# ── Service (LoadBalancer) ───────────────────────────────────────────────────

resource "kubernetes_service" "app" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = var.app_name
    }

    port {
      port        = 80
      target_port = 8000
      protocol    = "TCP"
    }
  }
}
