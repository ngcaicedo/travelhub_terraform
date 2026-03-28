variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "keep_tags_number" {
  description = "Number of images to keep per repository"
  type        = number
  default     = 5
}
