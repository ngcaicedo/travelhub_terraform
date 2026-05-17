output "pipeline_name" {
  value = aws_codepipeline.this.name
}

output "pipeline_arn" {
  value = aws_codepipeline.this.arn
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}
