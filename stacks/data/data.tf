data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/networking/terraform.tfstate"
    region = var.region
  }
}
