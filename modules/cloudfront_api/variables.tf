variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "frontend_url" {
  description = "CloudFront URL of the frontend (used as allowed CORS origin)"
  type        = string
}
