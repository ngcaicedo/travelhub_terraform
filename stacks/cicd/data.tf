data "terraform_remote_state" "registry" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/registry/terraform.tfstate"
    region = var.region
  }
}
