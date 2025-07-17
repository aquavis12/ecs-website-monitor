output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cloudfront.distribution_domain_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "website_url" {
  description = "URL of the website"
  value       = "https://${module.cloudfront.distribution_domain_name}"
}

output "alb_url" {
  description = "Direct URL to the ALB"
  value       = "http://${module.alb.alb_dns_name}"
}

output "synthetics_canary_name" {
  description = "Name of the CloudWatch Synthetics canary"
  value       = module.monitoring.canary_name
}