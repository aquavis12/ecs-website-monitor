variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
}