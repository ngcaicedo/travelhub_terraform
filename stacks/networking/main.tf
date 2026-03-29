data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

module "security_groups" {
  source = "../../modules/security_groups"

  vpc_id       = data.aws_vpc.default.id
  project_name = var.project_name
  environment  = var.environment
}
