output "frontend_bucket_name" {
  value = module.s3_website.bucket_name
}

output "frontend_distribution_id" {
  value = module.s3_website.distribution_id
}

output "frontend_url" {
  value = "https://${module.s3_website.distribution_url}"
}

output "api_cloudfront_url" {
  value = module.cloudfront_api.distribution_url
}

output "api_distribution_id" {
  value = module.cloudfront_api.distribution_id
}
