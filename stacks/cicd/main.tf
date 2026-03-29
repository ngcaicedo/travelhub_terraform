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

# --- CodePipeline (Source + Build) ---

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
