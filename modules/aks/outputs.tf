output "service_load_balancer_ip" {
  description = "External IP/hostname assigned by the LoadBalancer."
  value       = try(kubernetes_service.app.status[0].load_balancer[0].ingress[0].ip, "pending")
}

output "namespace" {
  value = kubernetes_namespace.app.metadata[0].name
}
