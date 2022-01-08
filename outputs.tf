output "lb_dns_frontend" {
  value = module.loadbalancing.lb_dns_frontend
}

output "lb_dns_backend" {
  value = module.loadbalancing.lb_dns_backend
}

output "lb_dns_database" {
  value = module.loadbalancing.lb_dns_database
}