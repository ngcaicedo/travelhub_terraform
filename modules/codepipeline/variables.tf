variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "service_name" {
  description = "Service name (e.g., users, security)"
  type        = string
}

variable "codestar_connection_arn" {
  description = "ARN of the CodeStar connection to GitHub"
  type        = string
}

variable "github_repo_id" {
  description = "GitHub repository in owner/repo format (e.g., jd-sant/travelhub_miso)"
  type        = string
}

variable "branch_name" {
  description = "Branch that triggers the pipeline"
  type        = string
  default     = "main"
}

variable "codebuild_project_name" {
  description = "Name of the CodeBuild project for the Build stage"
  type        = string
}
