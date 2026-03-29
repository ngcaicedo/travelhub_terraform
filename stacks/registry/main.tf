module "ecr" {
  source = "../../modules/ecr"

  repository_names = var.repository_names
  keep_tags_number = var.keep_tags_number
}
