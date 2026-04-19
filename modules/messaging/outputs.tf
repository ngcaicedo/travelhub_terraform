output "notifications_queue_url" {
  value = aws_sqs_queue.notifications.url
}

output "notifications_queue_arn" {
  value = aws_sqs_queue.notifications.arn
}

output "notifications_dlq_url" {
  value = aws_sqs_queue.notifications_dlq.url
}

output "notifications_dlq_arn" {
  value = aws_sqs_queue.notifications_dlq.arn
}

