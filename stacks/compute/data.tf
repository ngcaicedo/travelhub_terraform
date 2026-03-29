data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/networking/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "registry" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/registry/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "data" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/data/terraform.tfstate"
    region = var.region
  }
}
