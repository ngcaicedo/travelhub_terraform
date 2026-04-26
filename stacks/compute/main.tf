# ---------------------------------------------------------------------------
# ECS Task Execution Role (shared by all services)
# ---------------------------------------------------------------------------

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
        data.terraform_remote_state.data.outputs.security_config_secret_arn,
        data.terraform_remote_state.data.outputs.notifications_config_secret_arn,
        data.terraform_remote_state.data.outputs.payments_config_secret_arn,
      ]
    }]
  })
}

# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------

locals {
  networking = data.terraform_remote_state.networking.outputs
  registry   = data.terraform_remote_state.registry.outputs
  data_state = data.terraform_remote_state.data.outputs
}

# ---------------------------------------------------------------------------
# ECS Cluster
# ---------------------------------------------------------------------------

module "ecs_cluster" {
  source = "../../modules/ecs_cluster"

  cluster_name = "${var.project_name}-${var.environment}"
  project_name = var.project_name
  environment  = var.environment
}

# ---------------------------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------------------------

module "alb" {
  source = "../../modules/alb"

  vpc_id     = local.networking.vpc_id
  subnet_ids = local.networking.subnet_ids
  alb_sg_id  = local.networking.alb_sg_id

  project_name = var.project_name
  environment  = var.environment

  services = {
    # Cada servicio enumera explícitamente sus paths internal — ya no usamos
    # el comodín "/api/v1/internal*" para evitar colisiones cross-servicio.
    users = {
      port              = 8000
      health_check_path = "/health"
      priority          = 100
      path_patterns = [
        "/api/v1/users*",
        "/api/v1/internal/users*",
        "/api/v1/internal/verify-credentials",
      ]
    }
    security = {
      port              = 8000
      health_check_path = "/health"
      priority          = 200
      path_patterns     = ["/api/v1/auth*"]
    }
    reservations = {
      port              = 8000
      health_check_path = "/health"
      priority          = 50
      path_patterns = [
        "/api/v1/reservations*",
        "/api/v1/internal/reservations*",
        "/api/v1/hotel/reservations*",
      ]
    }
    payments = {
      port              = 8000
      health_check_path = "/health"
      priority          = 60
      path_patterns = [
        "/api/v1/payments*",
        "/api/v1/internal/payments*",
        "/api/v1/internal/refunds",
        "/api/v1/internal/payment-processing*",
        "/api/v1/internal/reservation-confirmations*",
      ]
    }
    notifications = {
      port              = 8000
      health_check_path = "/health"
      priority          = 70
      path_patterns = [
        "/api/v1/notifications*",
        "/api/v1/internal/payment-confirmations",
        "/api/v1/internal/reservation-updates",
        "/api/v1/internal/reservation-events",
      ]
    }
    properties = {
      port              = 8000
      health_check_path = "/health"
      priority          = 80
      path_patterns     = ["/api/v1/properties*", "/api/v1/internal/properties*"]
    }
    search = {
      port              = 8000
      health_check_path = "/health"
      priority          = 700
      path_patterns     = ["/api/v1/search*"]
    }
  }
}

# ---------------------------------------------------------------------------
# EventBridge Scheduler — Lambda + IAM roles
# ---------------------------------------------------------------------------

module "reservation_checker_lambda" {
  source = "../../modules/lambda"

  function_name = "reservation-checker"

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
}

resource "aws_scheduler_schedule_group" "reservations" {
  name = "${var.project_name}-${var.environment}-reservations"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Rol A: EventBridge Scheduler asume este rol para invocar Lambda
resource "aws_iam_role" "scheduler_invocation" {
  name = "${var.project_name}-${var.environment}-scheduler-invocation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_invocation_lambda" {
  name = "${var.project_name}-${var.environment}-scheduler-invoke-lambda"
  role = aws_iam_role.scheduler_invocation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = module.reservation_checker_lambda.function_arn
    }]
  })
}

# Rol B: ECS task role para el servicio reservations
resource "aws_iam_role" "reservations_task" {
  name = "${var.project_name}-${var.environment}-reservations-task"

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

resource "aws_iam_role_policy" "reservations_task_scheduler" {
  name = "${var.project_name}-${var.environment}-reservations-scheduler-policy"
  role = aws_iam_role.reservations_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "scheduler:CreateSchedule",
          "scheduler:DeleteSchedule",
        ]
        Resource = "arn:aws:scheduler:${var.region}:*:schedule/${aws_scheduler_schedule_group.reservations.name}/*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.scheduler_invocation.arn
      },
    ]
  })
}

# ---------------------------------------------------------------------------
# Task roles for SQS / SES (payments dispatches, notifications API + worker)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# payments: publica eventos en la cola de notificaciones
resource "aws_iam_role" "payments_task" {
  name               = "${var.project_name}-${var.environment}-payments-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy" "payments_task_sqs" {
  name = "${var.project_name}-${var.environment}-payments-sqs-policy"
  role = aws_iam_role.payments_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:GetQueueAttributes",
      ]
      Resource = local.data_state.notifications_queue_arn
    }]
  })
}

# notifications API: puede despachar correos vía SES (ver assembly.get_email_sender)
resource "aws_iam_role" "notifications_task" {
  name               = "${var.project_name}-${var.environment}-notifications-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy" "notifications_task_ses" {
  name = "${var.project_name}-${var.environment}-notifications-ses-policy"
  role = aws_iam_role.notifications_task.id

  # Resource = "*" porque en SES sandbox la operación SendRawEmail valida IAM
  # tanto sobre la identity del Source como sobre la del Destination
  # (que también debe estar verified). Restringir solo al sender provoca
  # AccessDenied al mandar a destinatarios verified que no son el sender.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ses:SendEmail",
        "ses:SendRawEmail",
      ]
      Resource = "*"
    }]
  })
}

# notifications-worker: consume SQS y envía SES
resource "aws_iam_role" "notifications_worker_task" {
  name               = "${var.project_name}-${var.environment}-notifications-worker-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy" "notifications_worker_task_policy" {
  name = "${var.project_name}-${var.environment}-notifications-worker-policy"
  role = aws_iam_role.notifications_worker_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility",
        ]
        Resource = local.data_state.notifications_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
        ]
        Resource = "*"
      },
    ]
  })
}

# ---------------------------------------------------------------------------
# ECS Services
# ---------------------------------------------------------------------------

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
    { name = "ALLOWED_CORS_ORIGIN", value = var.cors_allowed_origin },
    { name = "DEMO_SEED_ENABLED", value = "true" },
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
    { name = "ALLOWED_CORS_ORIGIN", value = var.cors_allowed_origin },
    { name = "DEMO_SEED_ENABLED", value = "true" },
  ]

  secrets = [
    { name = "RDS_HOSTNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_HOSTNAME::" },
    { name = "RDS_USERNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_USERNAME::" },
    { name = "RDS_PASSWORD", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_PASSWORD::" },
    { name = "RDS_DB_NAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_DB_NAME::" },
    { name = "JWT_SECRET_KEY", valueFrom = "${local.data_state.security_config_secret_arn}:JWT_SECRET_KEY::" },
    { name = "INTERNAL_API_KEY", valueFrom = "${local.data_state.security_config_secret_arn}:INTERNAL_API_KEY::" },
    { name = "SMTP_HOST", valueFrom = "${local.data_state.security_config_secret_arn}:SMTP_HOST::" },
    { name = "SMTP_PORT", valueFrom = "${local.data_state.security_config_secret_arn}:SMTP_PORT::" },
    { name = "SMTP_USER", valueFrom = "${local.data_state.security_config_secret_arn}:SMTP_USER::" },
    { name = "SMTP_PASSWORD", valueFrom = "${local.data_state.security_config_secret_arn}:SMTP_PASSWORD::" },
    { name = "SMTP_FROM", valueFrom = "${local.data_state.security_config_secret_arn}:SMTP_FROM::" },
  ]

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
}

module "reservations_service" {
  source = "../../modules/ecs_service"

  service_name       = "reservations"
  cluster_id         = module.ecs_cluster.cluster_id
  container_port     = 8000
  ecr_image_url      = "${local.registry.repository_urls["travelhub-reservations"]}:latest"
  desired_count      = var.desired_count
  subnet_ids         = local.networking.subnet_ids
  security_group_id  = local.networking.ecs_sg_id
  target_group_arn   = module.alb.target_group_arns["reservations"]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.reservations_task.arn

  environment_variables = [
    { name = "ENV", value = "production" },
    { name = "DB_SCHEMA", value = "reservations_schema" },
    { name = "DB_ECHO", value = "False" },
    { name = "RDS_PORT", value = "5432" },
    { name = "ALLOWED_CORS_ORIGIN", value = var.cors_allowed_origin },
    { name = "RESERVATION_SCHEDULER_ENABLED", value = "true" },
    { name = "RESERVATION_SCHEDULER_DELAY_MINUTES", value = "15" },
    { name = "AWS_REGION", value = var.region },
    { name = "LAMBDA_ARN", value = module.reservation_checker_lambda.function_arn },
    { name = "SCHEDULER_ROLE_ARN", value = aws_iam_role.scheduler_invocation.arn },
    { name = "SCHEDULER_GROUP_NAME", value = aws_scheduler_schedule_group.reservations.name },
    { name = "API_BASE_URL", value = "http://${module.alb.alb_dns_name}" },
    { name = "USERS_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
    { name = "PROPERTIES_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
    { name = "PAYMENTS_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
    { name = "NOTIFICATIONS_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
  ]

  secrets = [
    { name = "RDS_HOSTNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_HOSTNAME::" },
    { name = "RDS_USERNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_USERNAME::" },
    { name = "RDS_PASSWORD", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_PASSWORD::" },
    { name = "RDS_DB_NAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_DB_NAME::" },
    { name = "INTERNAL_API_KEY", valueFrom = "${local.data_state.security_config_secret_arn}:INTERNAL_API_KEY::" },
    { name = "JWT_SECRET_KEY", valueFrom = "${local.data_state.security_config_secret_arn}:JWT_SECRET_KEY::" },
  ]

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
}

module "payments_service" {
  source = "../../modules/ecs_service"

  service_name       = "payments"
  cluster_id         = module.ecs_cluster.cluster_id
  container_port     = 8000
  ecr_image_url      = "${local.registry.repository_urls["travelhub-payments"]}:latest"
  desired_count      = var.desired_count
  subnet_ids         = local.networking.subnet_ids
  security_group_id  = local.networking.ecs_sg_id
  target_group_arn   = module.alb.target_group_arns["payments"]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.payments_task.arn

  environment_variables = [
    { name = "DB_SCHEMA", value = "payments_schema" },
    { name = "DB_ECHO", value = "False" },
    { name = "RDS_PORT", value = "5432" },
    { name = "ALLOWED_CORS_ORIGIN", value = var.cors_allowed_origin },
    { name = "NOTIFICATIONS_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
    { name = "RESERVATIONS_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
    { name = "PROPERTIES_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
    { name = "ENFORCE_TLS_HEADER", value = "False" },
    { name = "PAYMENTS_COMPLIANCE_MODE", value = "False" },
    { name = "PAYMENT_PROVIDER", value = "fake_stripe" },
    { name = "PAYMENT_INTEGRITY_SECRET", value = "travelhub-payments-secret-change-in-prod" },
    { name = "PAYMENTS_DATA_ENCRYPTION_KEY", value = "travelhub-payments-encryption-key-change-in-prod" },
    { name = "STRIPE_SECRET_KEY", value = "" },
    { name = "STRIPE_PUBLISHABLE_KEY", value = "" },
    { name = "STRIPE_WEBHOOK_SECRET", value = "" },
    { name = "AWS_REGION", value = var.region },
    { name = "NOTIFICATIONS_DISPATCH_MODE", value = "sqs" },
    { name = "NOTIFICATIONS_QUEUE_URL", value = local.data_state.notifications_queue_url },
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

module "notifications_service" {
  source = "../../modules/ecs_service"

  service_name       = "notifications"
  cluster_id         = module.ecs_cluster.cluster_id
  container_port     = 8000
  ecr_image_url      = "${local.registry.repository_urls["travelhub-notifications"]}:latest"
  desired_count      = var.desired_count
  subnet_ids         = local.networking.subnet_ids
  security_group_id  = local.networking.ecs_sg_id
  target_group_arn   = module.alb.target_group_arns["notifications"]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.notifications_task.arn

  environment_variables = [
    { name = "DB_SCHEMA", value = "notifications_schema" },
    { name = "DB_ECHO", value = "False" },
    { name = "RDS_PORT", value = "5432" },
    { name = "PAYMENTS_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
    { name = "USERS_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
    { name = "SERVICE_MODE", value = "api" },
    { name = "AWS_REGION", value = var.region },
    { name = "NOTIFICATIONS_QUEUE_URL", value = local.data_state.notifications_queue_url },
    { name = "SES_FROM_ADDRESS", value = local.data_state.ses_sender_email },
    { name = "SES_REGION", value = var.region },
  ]

  secrets = [
    { name = "RDS_HOSTNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_HOSTNAME::" },
    { name = "RDS_USERNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_USERNAME::" },
    { name = "RDS_PASSWORD", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_PASSWORD::" },
    { name = "RDS_DB_NAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_DB_NAME::" },
    { name = "INTERNAL_API_KEY", valueFrom = "${local.data_state.security_config_secret_arn}:INTERNAL_API_KEY::" },
    { name = "SMTP_HOST", valueFrom = "${local.data_state.notifications_config_secret_arn}:SMTP_HOST::" },
    { name = "SMTP_PORT", valueFrom = "${local.data_state.notifications_config_secret_arn}:SMTP_PORT::" },
    { name = "SMTP_USER", valueFrom = "${local.data_state.notifications_config_secret_arn}:SMTP_USER::" },
    { name = "SMTP_PASSWORD", valueFrom = "${local.data_state.notifications_config_secret_arn}:SMTP_PASSWORD::" },
    { name = "SMTP_FROM", valueFrom = "${local.data_state.notifications_config_secret_arn}:SMTP_FROM::" },
  ]

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
}

module "properties_service" {
  source = "../../modules/ecs_service"

  service_name       = "properties"
  cluster_id         = module.ecs_cluster.cluster_id
  container_port     = 8000
  ecr_image_url      = "${local.registry.repository_urls["travelhub-properties"]}:latest"
  desired_count      = var.desired_count
  subnet_ids         = local.networking.subnet_ids
  security_group_id  = local.networking.ecs_sg_id
  target_group_arn   = module.alb.target_group_arns["properties"]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  environment_variables = [
    { name = "DB_SCHEMA", value = "properties_schema" },
    { name = "DB_ECHO", value = "False" },
    { name = "RDS_PORT", value = "5432" },
    { name = "ALLOWED_CORS_ORIGIN", value = var.cors_allowed_origin },
  ]

  secrets = [
    { name = "RDS_HOSTNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_HOSTNAME::" },
    { name = "RDS_USERNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_USERNAME::" },
    { name = "RDS_PASSWORD", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_PASSWORD::" },
    { name = "RDS_DB_NAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_DB_NAME::" },
  ]

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
}

# Worker que consume la cola SQS y despacha correos vía SES.
# No se registra en el ALB (servicio interno).
module "notifications_worker_service" {
  source = "../../modules/ecs_service"

  service_name       = "notifications-worker"
  cluster_id         = module.ecs_cluster.cluster_id
  container_port     = 8000
  ecr_image_url      = "${local.registry.repository_urls["travelhub-notifications"]}:latest"
  desired_count      = 1
  subnet_ids         = local.networking.subnet_ids
  security_group_id  = local.networking.ecs_sg_id
  target_group_arn   = null
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.notifications_worker_task.arn

  environment_variables = [
    { name = "SERVICE_MODE", value = "worker" },
    { name = "DB_SCHEMA", value = "notifications_schema" },
    { name = "DB_ECHO", value = "False" },
    { name = "RDS_PORT", value = "5432" },
    { name = "AWS_REGION", value = var.region },
    { name = "NOTIFICATIONS_QUEUE_URL", value = local.data_state.notifications_queue_url },
    { name = "SES_FROM_ADDRESS", value = local.data_state.ses_sender_email },
    { name = "SES_REGION", value = var.region },
    { name = "PAYMENTS_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
    { name = "USERS_SERVICE_URL", value = "http://${module.alb.alb_dns_name}" },
  ]

  secrets = [
    { name = "RDS_HOSTNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_HOSTNAME::" },
    { name = "RDS_USERNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_USERNAME::" },
    { name = "RDS_PASSWORD", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_PASSWORD::" },
    { name = "RDS_DB_NAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_DB_NAME::" },
    { name = "INTERNAL_API_KEY", valueFrom = "${local.data_state.security_config_secret_arn}:INTERNAL_API_KEY::" },
    { name = "SMTP_HOST", valueFrom = "${local.data_state.notifications_config_secret_arn}:SMTP_HOST::" },
    { name = "SMTP_PORT", valueFrom = "${local.data_state.notifications_config_secret_arn}:SMTP_PORT::" },
    { name = "SMTP_USER", valueFrom = "${local.data_state.notifications_config_secret_arn}:SMTP_USER::" },
    { name = "SMTP_PASSWORD", valueFrom = "${local.data_state.notifications_config_secret_arn}:SMTP_PASSWORD::" },
    { name = "SMTP_FROM", valueFrom = "${local.data_state.notifications_config_secret_arn}:SMTP_FROM::" },
  ]

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
}

module "search_service" {
  source = "../../modules/ecs_service"

  service_name       = "search"
  cluster_id         = module.ecs_cluster.cluster_id
  container_port     = 8000
  ecr_image_url      = "${local.registry.repository_urls["travelhub-search"]}:latest"
  desired_count      = var.desired_count
  subnet_ids         = local.networking.subnet_ids
  security_group_id  = local.networking.ecs_sg_id
  target_group_arn   = module.alb.target_group_arns["search"]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  environment_variables = [
    { name = "DB_SCHEMA", value = "search_schema" },
    { name = "DB_ECHO", value = "False" },
    { name = "RDS_PORT", value = "5432" },
    { name = "ALLOWED_CORS_ORIGIN", value = var.cors_allowed_origin },
    { name = "REDIS_HOST", value = local.data_state.redis_host },
    { name = "REDIS_PORT", value = tostring(local.data_state.redis_port) },
    { name = "REDIS_DB", value = "0" },
  ]

  secrets = [
    { name = "RDS_HOSTNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_HOSTNAME::" },
    { name = "RDS_USERNAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_USERNAME::" },
    { name = "RDS_PASSWORD", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_PASSWORD::" },
    { name = "RDS_DB_NAME", valueFrom = "${local.data_state.rds_credentials_secret_arn}:RDS_DB_NAME::" },
  ]

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
}
