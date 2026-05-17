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

variable "buildspec_path" {
  description = "Path to buildspec.yml within the repo"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the service"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
