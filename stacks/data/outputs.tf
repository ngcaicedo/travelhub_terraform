output "rds_address" {
  value = module.rds.address
}

output "rds_port" {
  value = module.rds.port
}

output "rds_credentials_secret_arn" {
  value = module.rds_credentials.secret_arn
}

output "security_config_secret_arn" {
  value = module.security_config.secret_arn
}

output "properties_config_secret_arn" {
  value = module.properties_config.secret_arn
}

output "notifications_config_secret_arn" {
  value = module.notifications_config.secret_arn
}

output "payments_config_secret_arn" {
  value = module.payments_config.secret_arn
}

output "redis_host" {
  value = module.elasticache.redis_host
}

output "redis_port" {
  value = module.elasticache.redis_port
}

output "notifications_queue_url" {
  value = module.messaging.notifications_queue_url
}

output "notifications_queue_arn" {
  value = module.messaging.notifications_queue_arn
}

output "notifications_dlq_url" {
  value = module.messaging.notifications_dlq_url
}

output "notifications_dlq_arn" {
  value = module.messaging.notifications_dlq_arn
}

output "ses_sender_email" {
  value = module.email.sender_email
}

output "ses_sender_identity_arn" {
  value = module.email.sender_identity_arn
}
