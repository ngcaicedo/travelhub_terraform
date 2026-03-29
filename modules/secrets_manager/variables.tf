variable "secret_name" {
  description = "Name of the secret"
  type        = string
}

variable "secret_values" {
  description = "Map of secret key-value pairs"
  type        = map(string)
  sensitive   = true
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
