variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "travelhub"
}

variable "environment" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "github_repo_id" {
  description = "GitHub repo in owner/repo format"
  type        = string
}

variable "branch_name" {
  description = "Branch that triggers the pipeline"
  type        = string
  default     = "main"
}

variable "frontend_github_repo_id" {
  description = "GitHub repo for the frontend in owner/repo format"
  type        = string
}
