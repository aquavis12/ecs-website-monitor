output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.website.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.website.name
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.website.arn
}