output "frontend_alb_dns" { value = module.alb.alb_dns_name }
output "service_discovery_namespace" { value = module.ecs_cluster.namespace_name }
