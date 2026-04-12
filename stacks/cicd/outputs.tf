output "codestar_connection_arn" {
  value = aws_codestarconnections_connection.github.arn
}

output "pipeline_users" {
  value = module.pipeline_users.pipeline_name
}

output "pipeline_security" {
  value = module.pipeline_security.pipeline_name
}

output "pipeline_reservations" {
  value = module.pipeline_reservations.pipeline_name
}

output "pipeline_payments" {
  value = module.pipeline_payments.pipeline_name
}

output "pipeline_notifications" {
  value = module.pipeline_notifications.pipeline_name
}

output "pipeline_properties" {
  value = module.pipeline_properties.pipeline_name
}

output "pipeline_search" {
  value = module.pipeline_search.pipeline_name
}

output "codebuild_users" {
  value = module.codebuild_users.project_name
}

output "codebuild_security" {
  value = module.codebuild_security.project_name
}

output "codebuild_reservations" {
  value = module.codebuild_reservations.project_name
}

output "codebuild_payments" {
  value = module.codebuild_payments.project_name
}

output "codebuild_notifications" {
  value = module.codebuild_notifications.project_name
}

output "codebuild_properties" {
  value = module.codebuild_properties.project_name
}

output "codebuild_search" {
  value = module.codebuild_search.project_name
}

output "pipeline_frontend" {
  value = module.pipeline_frontend.pipeline_name
}

output "codebuild_frontend" {
  value = module.codebuild_frontend.project_name
}
