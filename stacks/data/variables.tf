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

variable "db_name" {
  type    = string
  default = "travelhub"
}

variable "db_username" {
  type    = string
  default = "travelhub_user"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "publicly_accessible" {
  type    = bool
  default = false
}

variable "jwt_secret_key" {
  type      = string
  sensitive = true
}

variable "internal_api_key" {
  type      = string
  sensitive = true
}

variable "pricing_integrity_secret" {
  description = "HMAC-SHA256 secret used by properties to sign seasonal pricing rows."
  type        = string
  sensitive   = true
}

variable "smtp_host" {
  type    = string
  default = "smtp.gmail.com"
}

variable "smtp_port" {
  type    = string
  default = "587"
}

variable "smtp_user" {
  type      = string
  sensitive = true
}

variable "smtp_password" {
  type      = string
  sensitive = true
}

variable "smtp_from" {
  type = string
}

variable "stripe_secret_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "payment_integrity_secret" {
  type      = string
  sensitive = true
  default   = ""
}

variable "ses_sender_email" {
  description = "Correo remitente verificado en SES (ej: no-reply@travelhub-dev.com)"
  type        = string
  default     = ""
}

variable "fcm_project_id" {
  description = "Project ID del proyecto Firebase usado por FCM HTTP v1 (push notifications mobile)."
  type        = string
  default     = ""
}

variable "fcm_service_account_json" {
  description = "JSON completo de la service account de Firebase con permisos de FCM. Se inyecta como string al servicio notifications."
  type        = string
  sensitive   = true
  default     = ""
}

variable "new_relic_license_key" {
  description = "New Relic license key for APM agent data ingestion"
  type        = string
  sensitive   = true
  default     = ""
}
