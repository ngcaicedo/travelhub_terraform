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

output "reservations_queue_url" {
  value = aws_sqs_queue.reservations.url
}

output "reservations_queue_arn" {
  value = aws_sqs_queue.reservations.arn
}

output "reservations_dlq_url" {
  value = aws_sqs_queue.reservations_dlq.url
}

output "reservations_dlq_arn" {
  value = aws_sqs_queue.reservations_dlq.arn
}
