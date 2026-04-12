output "distribution_id" {
  value = aws_cloudfront_distribution.api.id
}

output "distribution_url" {
  value = aws_cloudfront_distribution.api.domain_name
}
