locals {
  handler_code = <<-PYTHON
import json
import logging
import urllib.error
import urllib.request

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    reservation_id = event.get("reservation_id")
    api_url = event.get("api_url")

    if not reservation_id or not api_url:
        logger.error("Evento invalido: faltan reservation_id o api_url")
        raise ValueError("Evento invalido: faltan reservation_id o api_url")

    logger.info("Verificando reserva %s -> %s", reservation_id, api_url)

    req = urllib.request.Request(
        url=api_url,
        method="GET",
        headers={"Content-Type": "application/json"},
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            body = json.loads(response.read().decode("utf-8"))
            logger.info(
                "Reserva %s -> status_before=%s status_after=%s action=%s",
                reservation_id,
                body.get("status_before"),
                body.get("status_after"),
                body.get("action_applied"),
            )
            return {"statusCode": 200, "body": body}
    except urllib.error.HTTPError as exc:
        logger.error("HTTP %s al verificar reserva %s", exc.code, reservation_id)
        raise
    except Exception as exc:
        logger.error("Error inesperado en reserva %s: %s", reservation_id, str(exc))
        raise
PYTHON
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_payload.zip"

  source {
    content  = local.handler_code
    filename = "lambda_function.py"
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14

  tags = {
    Name = "/aws/lambda/${var.function_name}"
  }
}

resource "aws_iam_role" "lambda_execution" {
  name = "${var.function_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "${var.function_name}-logs-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
    }]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_execution.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  timeout          = 30

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = {
    Name        = var.function_name
    Project     = var.project_name
    Environment = var.environment
  }
}
