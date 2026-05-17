output "alarm_names" {
  description = "Names of the created CloudWatch alarms."
  value       = [for a in aws_cloudwatch_metric_alarm.this : a.alarm_name]
}

output "alarm_arns" {
  description = "ARNs of the created CloudWatch alarms."
  value       = [for a in aws_cloudwatch_metric_alarm.this : a.arn]
}
