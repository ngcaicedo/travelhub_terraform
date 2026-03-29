resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_secrets_access" {
  name = "${var.project_name}-${var.environment}-ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        data.terraform_remote_state.data.outputs.rds_credentials_secret_arn,
        data.terraform_remote_state.data.outputs.security_config_secret_arn
      ]
    }]
  })
}

locals {
  networking = data.terraform_remote_state.networking.outputs
  registry   = data.terraform_remote_state.registry.outputs
  data_state = data.terraform_remote_state.data.outputs
}

module "ecs_cluster" {
  source = "../../modules/ecs_cluster"

  cluster_name = "${var.project_name}-${var.environment}"
  project_name = var.project_name
  environment  = var.environment
}

module "alb" {
  source = "../../modules/alb"

  vpc_id     = local.networking.vpc_id
  subnet_ids = local.networking.subnet_ids
  alb_sg_id  = local.networking.alb_sg_id

  project_name = var.project_name
  environment  = var.environment

  services = {
    users = {
      port              = 8000
      health_check_path = "/health"
      priority          = 100
      path_patterns     = ["/api/v1/users*", "/api/v1/internal*"]
    }
    security = {
      port              = 8000
      health_check_path = "/health"
      priority          = 200
      path_patterns     = ["/api/v1/auth*"]
    }
  }
}

module "users_service" {
  source = "../../modules/ecs_service"

  service_name       = "users"
  cluster_id         = module.ecs_cluster.cluster_id
  container_port     = 8000
  ecr_image_url      = "${local.registry.repository_urls["travelhub-users"]}:latest"
  desired_count      = var.desired_count
  subnet_ids         = local.networking.subnet_ids
  security_group_id  = local.networking.ecs_sg_id
  target_group_arn   = module.alb.target_group_arns["users"]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  environment_variables = [
    { name = "DB_SCHEMA", value = "users_schema" },
    { name = "DB_ECHO", value = "False" },
    { name = "RDS_PORT", value = "5432" },
  ]

  secrets = [
    { name = "RDS_HOSTNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_HOSTNAME::" },
    { name = "RDS_USERNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_USERNAME::" },
    { name = "RDS_PASSWORD", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_PASSWORD::" },
    { name = "RDS_DB_NAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_DB_NAME::" },
    { name = "INTERNAL_API_KEY", valueFrom = "${local.data_state.security_config_secret_arn}:INTERNAL_API_KEY::" },
  ]

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
}

module "security_service" {
  source = "../../modules/ecs_service"

  service_name       = "security"
  cluster_id         = module.ecs_cluster.cluster_id
  container_port     = 8000
  ecr_image_url      = "${local.registry.repository_urls["travelhub-security"]}:latest"
  desired_count      = var.desired_count
  subnet_ids         = local.networking.subnet_ids
  security_group_id  = local.networking.ecs_sg_id
  target_group_arn   = module.alb.target_group_arns["security"]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  environment_variables = [
    { name = "DB_SCHEMA", value = "security_schema" },
    { name = "DB_ECHO", value = "False" },
    { name = "RDS_PORT", value = "5432" },
    { name = "USERS_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
  ]

  secrets = [
    { name = "RDS_HOSTNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_HOSTNAME::" },
    { name = "RDS_USERNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_USERNAME::" },
    { name = "RDS_PASSWORD", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_PASSWORD::" },
    { name = "RDS_DB_NAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_DB_NAME::" },
    { name = "JWT_SECRET_KEY", valueFrom = "${local.data_state.security_config_secret_arn}:JWT_SECRET_KEY::" },
    { name = "INTERNAL_API_KEY", valueFrom = "${local.data_state.security_config_secret_arn}:INTERNAL_API_KEY::" },
  ]

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
}
