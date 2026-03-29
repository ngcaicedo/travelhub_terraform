variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "task_cpu" {
  description = "Task CPU units"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Task memory in MiB"
  type        = string
  default     = "1024"
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "ecr_image_url" {
  description = "ECR image URL (repo:tag)"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS tasks"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN (optional)"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "List of environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "List of secrets from Secrets Manager/SSM for the container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region for CloudWatch logs"
  type        = string
  default     = "us-east-1"
}
