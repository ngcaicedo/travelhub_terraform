locals {
  registry = data.terraform_remote_state.registry.outputs
  compute  = data.terraform_remote_state.compute.outputs
}

resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-${var.environment}-github"
  provider_type = "GitHub"

  tags = {
    Name        = "${var.project_name}-${var.environment}-github"
    Environment = var.environment
  }
}

# --- CodeBuild projects ---

module "codebuild_users" {
  source = "../../modules/codebuild"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "users"
  buildspec_path     = "services/users/buildspec.yml"
  ecr_repository_url = local.registry.repository_urls["travelhub-users"]
  region             = var.region
}

module "codebuild_security" {
  source = "../../modules/codebuild"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "security"
  buildspec_path     = "services/security/buildspec.yml"
  ecr_repository_url = local.registry.repository_urls["travelhub-security"]
  region             = var.region
}

module "codebuild_reservations" {
  source = "../../modules/codebuild"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "reservations"
  buildspec_path     = "services/reservations/buildspec.yml"
  ecr_repository_url = local.registry.repository_urls["travelhub-reservations"]
  region             = var.region
}

module "codebuild_payments" {
  source = "../../modules/codebuild"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "payments"
  buildspec_path     = "services/payments/buildspec.yml"
  ecr_repository_url = local.registry.repository_urls["travelhub-payments"]
  region             = var.region
}

module "codebuild_notifications" {
  source = "../../modules/codebuild"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "notifications"
  buildspec_path     = "services/notifications/buildspec.yml"
  ecr_repository_url = local.registry.repository_urls["travelhub-notifications"]
  region             = var.region
}

module "codebuild_properties" {
  source = "../../modules/codebuild"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "properties"
  buildspec_path     = "services/properties/buildspec.yml"
  ecr_repository_url = local.registry.repository_urls["travelhub-properties"]
  region             = var.region
}

module "codebuild_search" {
  source = "../../modules/codebuild"

  project_name       = var.project_name
  environment        = var.environment
  service_name       = "search"
  buildspec_path     = "services/search/buildspec.yml"
  ecr_repository_url = local.registry.repository_urls["travelhub-search"]
  region             = var.region
}

# --- CodePipeline (Source + Build + Deploy) ---

module "pipeline_users" {
  source = "../../modules/codepipeline"

  project_name            = var.project_name
  environment             = var.environment
  service_name            = "users"
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  github_repo_id          = var.github_repo_id
  branch_name             = var.branch_name
  codebuild_project_name  = module.codebuild_users.project_name
  ecs_cluster_name        = local.compute.cluster_name
  ecs_service_name        = local.compute.users_service_name
}

module "pipeline_security" {
  source = "../../modules/codepipeline"

  project_name            = var.project_name
  environment             = var.environment
  service_name            = "security"
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  github_repo_id          = var.github_repo_id
  branch_name             = var.branch_name
  codebuild_project_name  = module.codebuild_security.project_name
  ecs_cluster_name        = local.compute.cluster_name
  ecs_service_name        = local.compute.security_service_name
}

module "pipeline_reservations" {
  source = "../../modules/codepipeline"

  project_name            = var.project_name
  environment             = var.environment
  service_name            = "reservations"
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  github_repo_id          = var.github_repo_id
  branch_name             = var.branch_name
  codebuild_project_name  = module.codebuild_reservations.project_name
  ecs_cluster_name        = local.compute.cluster_name
  ecs_service_name        = local.compute.reservations_service_name
}

module "pipeline_payments" {
  source = "../../modules/codepipeline"

  project_name            = var.project_name
  environment             = var.environment
  service_name            = "payments"
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  github_repo_id          = var.github_repo_id
  branch_name             = var.branch_name
  codebuild_project_name  = module.codebuild_payments.project_name
  ecs_cluster_name        = local.compute.cluster_name
  ecs_service_name        = local.compute.payments_service_name
}

module "pipeline_notifications" {
  source = "../../modules/codepipeline"

  project_name            = var.project_name
  environment             = var.environment
  service_name            = "notifications"
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  github_repo_id          = var.github_repo_id
  branch_name             = var.branch_name
  codebuild_project_name  = module.codebuild_notifications.project_name
  ecs_cluster_name        = local.compute.cluster_name
  ecs_service_name        = local.compute.notifications_service_name
}

module "pipeline_properties" {
  source = "../../modules/codepipeline"

  project_name            = var.project_name
  environment             = var.environment
  service_name            = "properties"
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  github_repo_id          = var.github_repo_id
  branch_name             = var.branch_name
  codebuild_project_name  = module.codebuild_properties.project_name
  ecs_cluster_name        = local.compute.cluster_name
  ecs_service_name        = local.compute.properties_service_name
}

module "pipeline_search" {
  source = "../../modules/codepipeline"

  project_name            = var.project_name
  environment             = var.environment
  service_name            = "search"
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  github_repo_id          = var.github_repo_id
  branch_name             = var.branch_name
  codebuild_project_name  = module.codebuild_search.project_name
  ecs_cluster_name        = local.compute.cluster_name
  ecs_service_name        = local.compute.search_service_name
}
