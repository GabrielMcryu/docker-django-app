output "app_load_balancer_ip" {
  description = "Public IP / hostname of the Django application LoadBalancer service."
  value       = module.kubernetes_app.service_load_balancer_ip
}