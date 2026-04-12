locals {
  compute = data.terraform_remote_state.compute.outputs
}

module "s3_website" {
  source = "../../modules/s3_website"

  project_name = var.project_name
  environment  = var.environment
}

module "cloudfront_api" {
  source = "../../modules/cloudfront_api"

  project_name = var.project_name
  environment  = var.environment
  alb_dns_name = local.compute.alb_dns_name
}
