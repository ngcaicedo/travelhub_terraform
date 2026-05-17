resource "aws_cloudwatch_metric_alarm" "this" {
  count               = length(var.alarms)
  alarm_name          = var.alarms[count.index].name
  comparison_operator = var.alarms[count.index].comparison_operator
  evaluation_periods  = var.alarms[count.index].evaluation_periods
  metric_name         = var.alarms[count.index].metric_name
  namespace           = var.alarms[count.index].namespace
  period              = var.alarms[count.index].period
  statistic           = var.alarms[count.index].statistic
  threshold           = var.alarms[count.index].threshold
  alarm_description   = var.alarms[count.index].description
  actions_enabled     = var.alarms[count.index].actions_enabled
  alarm_actions       = var.alarms[count.index].alarm_actions
  ok_actions          = var.alarms[count.index].ok_actions
  dimensions          = var.alarms[count.index].dimensions
  treat_missing_data  = var.alarms[count.index].treat_missing_data
}
