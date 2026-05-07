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
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.21"
    }
  }

  backend "s3" {}
}

provider "postgresql" {
  host            = module.rds.address
  port            = module.rds.port
  database        = var.db_name
  username        = var.db_username
  password        = var.db_password
  sslmode         = "require"
  superuser       = false
  connect_timeout = 15
}
