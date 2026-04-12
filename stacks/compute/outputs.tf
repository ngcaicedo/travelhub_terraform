output "cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "listener_arn" {
  value = module.alb.listener_arn
}

output "target_group_names" {
  value = module.alb.target_group_names
}

output "users_service_name" {
  value = module.users_service.service_name
}

output "security_service_name" {
  value = module.security_service.service_name
}

output "reservations_service_name" {
  value = module.reservations_service.service_name
}

output "payments_service_name" {
  value = module.payments_service.service_name
}

output "notifications_service_name" {
  value = module.notifications_service.service_name
}

output "properties_service_name" {
  value = module.properties_service.service_name
}

output "search_service_name" {
  value = module.search_service.service_name
}

output "scheduler_invocation_role_arn" {
  value = aws_iam_role.scheduler_invocation.arn
}

output "reservation_checker_lambda_arn" {
  value = module.reservation_checker_lambda.function_arn
}
