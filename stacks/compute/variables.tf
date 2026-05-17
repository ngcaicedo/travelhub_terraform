variable "alarms" {
  description = "Lista opcional de alarmas CloudWatch para override. Si es null, se usan defaults del stack."
  type = list(object({
    name                = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    description         = string
    actions_enabled     = bool
    alarm_actions       = list(string)
    ok_actions          = list(string)
    dimensions          = map(string)
    treat_missing_data  = string
  }))
  default  = null
  nullable = true
}
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "travelhub"
}

variable "environment" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "cors_allowed_origin" {
  description = "Comma-separated list of allowed CORS origins (e.g. https://d19ehjvpcjhpoj.cloudfront.net)"
  type        = string
  default     = "http://localhost:3000,http://127.0.0.1:3000"
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "service_min_capacity" {
  description = "Minimum number of tasks per web service. Bumped to avoid cold-start at test ramp."
  type        = number
  default     = 1
}

variable "service_max_capacity" {
  description = "Maximum number of tasks per web service."
  type        = number
  default     = 15
}

variable "request_count_per_target" {
  description = "Target RequestCountPerTarget for ALB-based autoscaling. Null disables this policy."
  type        = number
  default     = 50
}
