output "codestar_connection_arn" {
  value = aws_codestarconnections_connection.github.arn
}

output "pipeline_users" {
  value = module.pipeline_users.pipeline_name
}

output "pipeline_security" {
  value = module.pipeline_security.pipeline_name
}

output "codebuild_users" {
  value = module.codebuild_users.project_name
}

output "codebuild_security" {
  value = module.codebuild_security.project_name
}
