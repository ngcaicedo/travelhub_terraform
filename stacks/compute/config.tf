provider "aws" {
  region = var.region

  default_tags {
    tags = {
      terraform   = true
      project     = var.project_name
      environment = var.environment
    }
  }
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2"
    }
  }

  backend "s3" {}
}
