resource "aws_sqs_queue" "notifications_dlq" {
  name                       = "${var.project_name}-${var.environment}-notifications-dlq"
  message_retention_seconds  = 1209600 # 14 días
  visibility_timeout_seconds = 60

  tags = {
    Name    = "${var.project_name}-${var.environment}-notifications-dlq"
    Purpose = "notifications-dead-letter"
  }
}

resource "aws_sqs_queue" "notifications" {
  name                       = "${var.project_name}-${var.environment}-notifications-queue"
  message_retention_seconds  = 345600 # 4 días
  visibility_timeout_seconds = var.notifications_visibility_timeout_seconds
  receive_wait_time_seconds  = 20 # long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name    = "${var.project_name}-${var.environment}-notifications-queue"
    Purpose = "notifications"
  }
}

