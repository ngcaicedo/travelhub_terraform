variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "internal_api_key_secret_arn" {
  description = "ARN del secret de Secrets Manager con la clave INTERNAL_API_KEY que la Lambda inyecta al llamar endpoints internos. Vacío = sin auth (modo legacy)."
  type        = string
  default     = ""
}
