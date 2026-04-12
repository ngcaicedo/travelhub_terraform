variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "buildspec_path" {
  description = "Path to buildspec.yml within the repo"
  type        = string
  default     = "buildspec.yml"
}

variable "frontend_bucket_name" {
  description = "S3 bucket name where built assets are deployed"
  type        = string
}

variable "frontend_distribution_id" {
  description = "CloudFront distribution ID for the frontend (used for cache invalidation)"
  type        = string
}

variable "api_cloudfront_url" {
  description = "CloudFront domain name in front of the ALB (e.g. dXXXX.cloudfront.net)"
  type        = string
}
