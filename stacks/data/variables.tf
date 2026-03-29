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
