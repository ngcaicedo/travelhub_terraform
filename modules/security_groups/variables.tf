variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (development, production)"
  type        = string
}

variable "db_public_access_cidrs" {
  description = "Lista de CIDRs autorizados a alcanzar Postgres (5432) desde Internet. Vacío = sin acceso público."
  type        = list(string)
  default     = []
}
