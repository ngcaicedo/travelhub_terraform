variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "max_receive_count" {
  description = "SQS redrive: número máximo de recepciones antes de mover a DLQ"
  type        = number
  default     = 5
}

variable "notifications_visibility_timeout_seconds" {
  description = "Tiempo que un mensaje queda invisible mientras lo procesa un consumer"
  type        = number
  default     = 60
}

variable "reservations_visibility_timeout_seconds" {
  type    = number
  default = 60
}
