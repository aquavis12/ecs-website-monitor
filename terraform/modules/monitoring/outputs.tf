output "canary_name" {
  description = "Name of the CloudWatch Synthetics canary"
  value       = aws_synthetics_canary.website.name
}

output "canary_arn" {
  description = "ARN of the CloudWatch Synthetics canary"
  value       = aws_synthetics_canary.website.arn
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.website.dashboard_name}"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for synthetics artifacts"
  value       = aws_s3_bucket.synthetics.bucket
}