variable "alarms" {
  description = "Lista de alarmas CloudWatch a crear. Ver ejemplo en terraform.tfvars.example."
  type = any
  default = []
}
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

variable "cors_allowed_origin" {
  description = "Comma-separated list of allowed CORS origins (e.g. https://d19ehjvpcjhpoj.cloudfront.net)"
  type        = string
  default     = "http://localhost:3000,http://127.0.0.1:3000"
}

variable "desired_count" {
  type    = number
  default = 1
}
