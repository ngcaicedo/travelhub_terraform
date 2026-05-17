variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "sender_email" {
  description = "Dirección de correo remitente (se verifica via SES email identity)"
  type        = string
}
