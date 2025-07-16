output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
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
  value       = "http://${module.alb.alb_dns_name}"
}

output "synthetics_canary_name" {
  description = "Name of the CloudWatch Synthetics canary"
  value       = module.monitoring.canary_name
}