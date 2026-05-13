locals {
  handler_code = <<-PYTHON
import json
import logging
import os
import urllib.error
import urllib.request

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_secret_cache = {"value": None}


def _get_internal_api_key():
    if _secret_cache["value"] is not None:
        return _secret_cache["value"]
    secret_arn = os.environ.get("INTERNAL_API_KEY_SECRET_ARN")
    if not secret_arn:
        return ""
    client = boto3.client("secretsmanager")
    raw = client.get_secret_value(SecretId=secret_arn)["SecretString"]
    payload = json.loads(raw)
    _secret_cache["value"] = payload.get("INTERNAL_API_KEY", "")
    return _secret_cache["value"]


def lambda_handler(event, context):
    reservation_id = event.get("reservation_id")
    api_url = event.get("api_url")

    if not reservation_id or not api_url:
        logger.error("Evento invalido: faltan reservation_id o api_url")
        raise ValueError("Evento invalido: faltan reservation_id o api_url")

    logger.info("Disparando job %s -> %s", reservation_id, api_url)

    headers = {"Content-Type": "application/json"}
    api_key = _get_internal_api_key()
    if api_key:
        headers["X-Internal-Api-Key"] = api_key

    req = urllib.request.Request(
        url=api_url,
        method="POST",
        data=json.dumps({}).encode("utf-8"),
        headers=headers,
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            raw = response.read().decode("utf-8")
            try:
                body = json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                body = {"raw": raw}
            logger.info("Job %s ok -> %s", reservation_id, body)
            return {"statusCode": 200, "body": body}
    except urllib.error.HTTPError as exc:
        logger.error("HTTP %s al disparar job %s: %s", exc.code, reservation_id, exc.read())
        raise
    except Exception as exc:
        logger.error("Error inesperado en job %s: %s", reservation_id, str(exc))
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

resource "aws_iam_role_policy" "lambda_secrets" {
  count = var.internal_api_key_secret_arn != "" ? 1 : 0

  name = "${var.function_name}-secrets-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = var.internal_api_key_secret_arn
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

  environment {
    variables = {
      INTERNAL_API_KEY_SECRET_ARN = var.internal_api_key_secret_arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = {
    Name        = var.function_name
    Project     = var.project_name
    Environment = var.environment
  }
}
