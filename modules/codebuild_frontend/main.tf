data "aws_caller_identity" "current" {}

resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-${var.environment}-frontend-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-codebuild-role"
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.project_name}-${var.environment}-frontend-codebuild-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_codebuild_project" "this" {
  name         = "${var.project_name}-${var.environment}-frontend"
  service_role = aws_iam_role.codebuild.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec_path
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name  = "FRONTEND_BUCKET_NAME"
      value = var.frontend_bucket_name
    }

    environment_variable {
      name  = "FRONTEND_DISTRIBUTION_ID"
      value = var.frontend_distribution_id
    }

    # All services share the same CloudFront/ALB base URL — ALB routes by path
    environment_variable {
      name  = "NUXT_PUBLIC_USERS_API_BASE"
      value = "https://${var.api_cloudfront_url}"
    }

    environment_variable {
      name  = "NUXT_PUBLIC_SECURITY_API_BASE"
      value = "https://${var.api_cloudfront_url}"
    }

    environment_variable {
      name  = "NUXT_PUBLIC_PROPERTIES_API_BASE"
      value = "https://${var.api_cloudfront_url}"
    }

    environment_variable {
      name  = "NUXT_PUBLIC_RESERVATIONS_API_BASE"
      value = "https://${var.api_cloudfront_url}"
    }

    environment_variable {
      name  = "NUXT_PUBLIC_SEARCH_API_BASE"
      value = "https://${var.api_cloudfront_url}"
    }

    environment_variable {
      name  = "NUXT_PUBLIC_PAYMENTS_API_BASE"
      value = "https://${var.api_cloudfront_url}"
    }
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-frontend"
    Project = var.project_name
  }
}
