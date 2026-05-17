variable "alarms" {
  description = "List of CloudWatch alarms to create. Each element is a map with alarm configuration."
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
}