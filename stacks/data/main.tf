module "rds" {
  source = "../../modules/rds"

  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  subnet_ids        = data.terraform_remote_state.networking.outputs.subnet_ids
  security_group_id = data.terraform_remote_state.networking.outputs.rds_sg_id

  skip_final_snapshot = var.skip_final_snapshot
  publicly_accessible = var.publicly_accessible

  project_name = var.project_name
  environment  = var.environment
}

# Postgres extensions on the shared RDS.
# `unaccent` is required by services/properties for accent-insensitive city
# filtering (e.g. ?city=Bogota matches "Bogotá, Colombia").
resource "postgresql_extension" "unaccent" {
  name = "unaccent"

  depends_on = [module.rds]
}

module "rds_credentials" {
  source = "../../modules/secrets_manager"

  secret_name = "${var.project_name}/${var.environment}/rds/credentials"
  secret_values = {
    RDS_HOSTNAME = module.rds.address
    RDS_PORT     = tostring(module.rds.port)
    RDS_USERNAME = var.db_username
    RDS_PASSWORD = var.db_password
    RDS_DB_NAME  = var.db_name
  }

  project_name = var.project_name
  environment  = var.environment
}

module "security_config" {
  source = "../../modules/secrets_manager"

  secret_name = "${var.project_name}/${var.environment}/security/config"
  secret_values = {
    JWT_SECRET_KEY   = var.jwt_secret_key
    INTERNAL_API_KEY = var.internal_api_key
    SMTP_HOST        = var.smtp_host
    SMTP_PORT        = var.smtp_port
    SMTP_USER        = var.smtp_user
    SMTP_PASSWORD    = var.smtp_password
    SMTP_FROM        = var.smtp_from
  }

  project_name = var.project_name
  environment  = var.environment
}

module "notifications_config" {
  source = "../../modules/secrets_manager"

  secret_name = "${var.project_name}/${var.environment}/notifications/config"
  secret_values = {
    SMTP_HOST                = var.smtp_host
    SMTP_PORT                = var.smtp_port
    SMTP_USER                = var.smtp_user
    SMTP_PASSWORD            = var.smtp_password
    SMTP_FROM                = var.smtp_from
    FCM_PROJECT_ID           = var.fcm_project_id
    FCM_SERVICE_ACCOUNT_JSON = var.fcm_service_account_json
  }

  project_name = var.project_name
  environment  = var.environment
}

module "payments_config" {
  source = "../../modules/secrets_manager"

  secret_name = "${var.project_name}/${var.environment}/payments/config"
  secret_values = {
    STRIPE_SECRET_KEY        = var.stripe_secret_key
    PAYMENT_INTEGRITY_SECRET = var.payment_integrity_secret
  }

  project_name = var.project_name
  environment  = var.environment
}

module "newrelic_config" {
  source = "../../modules/secrets_manager"

  secret_name = "${var.project_name}/${var.environment}/newrelic/config"
  secret_values = {
    NEW_RELIC_LICENSE_KEY = var.new_relic_license_key
  }

  project_name = var.project_name
  environment  = var.environment
}

module "elasticache" {
  source = "../../modules/elasticache"

  cluster_name      = "${var.project_name}-${var.environment}"
  subnet_ids        = data.terraform_remote_state.networking.outputs.subnet_ids
  security_group_id = data.terraform_remote_state.networking.outputs.elasticache_sg_id

  project_name = var.project_name
  environment  = var.environment
}

module "messaging" {
  source = "../../modules/messaging"

  project_name = var.project_name
  environment  = var.environment
}

module "email" {
  source = "../../modules/email"

  project_name = var.project_name
  environment  = var.environment
  sender_email = var.ses_sender_email
}
