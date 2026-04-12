data "terraform_remote_state" "compute" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/compute/terraform.tfstate"
    region = var.region
  }
}
