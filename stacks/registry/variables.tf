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

variable "repository_names" {
  type = list(string)
  default = [
    "travelhub-users",
    "travelhub-security",
    "travelhub-reservations",
    "travelhub-payments",
    "travelhub-notifications",
    "travelhub-properties",
    "travelhub-search",
  ]
}

variable "keep_tags_number" {
  type    = number
  default = 5
}
