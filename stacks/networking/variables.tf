variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "travelhub"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "db_public_access_cidrs" {
  description = "Lista de CIDRs autorizados a alcanzar Postgres (5432) desde Internet. Vacío = sin acceso público."
  type        = list(string)
  default     = []
}
