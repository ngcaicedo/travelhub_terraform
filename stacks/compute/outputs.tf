output "cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "listener_arn" {
  value = module.alb.listener_arn
}

output "users_service_name" {
  value = module.users_service.service_name
}

output "security_service_name" {
  value = module.security_service.service_name
}

output "target_group_names" {
  value = module.alb.target_group_names
}
