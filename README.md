# CloudWatch Synthetics Canary Monitoring Project

A comprehensive demonstration of **AWS CloudWatch Synthetics Canary** capabilities for advanced website monitoring, using containerized web application deployment with ECS Fargate. Built with Terraform modules for infrastructure as code.

> **Understanding CloudWatch Synthetics Canaries**  
> This project is primarily focused on demonstrating how CloudWatch Synthetics Canaries work to provide proactive monitoring from an end-user perspective. The containerized website deployment using ECS serves as the application being monitored.
![Canary types](/website/src/canary%20types.png)
![Website](/website/src/image.png)

## Why CloudWatch Synthetics is the Star

CloudWatch Synthetics Canaries are the cornerstone of this project, offering capabilities that traditional monitoring solutions can't match:

- **End-User Perspective**: Simulates real user interactions to detect issues before your actual users do
- **Proactive Monitoring**: Runs scheduled checks every 5 minutes, ensuring constant vigilance
- **Visual Insights**: Captures screenshots of your website during tests for visual verification
- **Performance Metrics**: Tracks load times, rendering performance, and resource usage
- **Global Testing**: Tests your application from multiple AWS regions to ensure global availability
- **Custom Alerting**: Triggers notifications when availability or performance thresholds are breached

With CloudWatch Synthetics, you're not just monitoring server health—you're ensuring the complete user experience works flawlessly.

## Architecture

- **CloudFront** - Global content delivery network
- **Application Load Balancer** - Traffic distribution and health checks
- **ECS Fargate** - Serverless container orchestration
- **ECR** - Private container registry
- **CloudWatch Synthetics** - Automated website monitoring
- **Nginx** - High-performance web server for static content
- **Terraform Modules** - Modular infrastructure as code

## Project Structure

```
cloudwatch-synthetics-demo/
├── terraform/
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Input variables (no defaults)
│   ├── terraform.tfvars      # Variable values
│   ├── null_resources.tf     # S3  cleanup logic
│   ├── outputs.tf            # Output values
│   └── modules/
│       ├── networking/       # VPC, subnets, security groups
│       ├── ecr/              # Container registry
│       ├── cloudfront/       # CloudFront distribution
│       ├── alb/              # Application Load Balancer
│       ├── ecs/              # ECS cluster and services
│       └── monitoring/       # CloudWatch Synthetics
├── website/
│   ├── src/                  # Static website files
│   │   ├── index.html        # Main HTML page
│   │   ├── styles.css        # Styling and responsive design
│   │   └── script.js         # Interactive functionality
│   ├── Dockerfile            # Container definition
└── .gitignore                # Git ignore file
```

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Docker installed
- Terraform >= 1.0 installed

### Deployment Steps

#### Step 1: Clone the project and Create ECR Repository First
```bash
#Clone the project
git clone https://github.com/aquavis12/ecs-website-monitor

# Initialize Terraform
cd terraform
terraform init

# Create only the ECR repository
terraform apply -target="module.ecr" -auto-approve

# Get the ECR repository URL
ECR_REPO=$(terraform output -raw ecr_repository_url)
echo "ECR Repository URL: $ECR_REPO"
```

#### Step 2: Build and Push Docker Image to ECR
```bash
# Navigate to website directory
cd ../website

# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"  # or your preferred region

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

# Build the Docker image
docker build -t cloudwatch-synthetics-demo-website .

# Tag the image for ECR
docker tag cloudwatch-synthetics-demo-website:latest $ECR_REPO:latest

# Push the image to ECR
docker push $ECR_REPO:latest
```

#### Step 3: Deploy Complete Infrastructure
```bash
# Return to terraform directory
cd ../terraform

# Deploy the rest of the infrastructure
terraform apply -auto-approve

# Get the CloudFront URL
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)
echo "Website URL: https://$CLOUDFRONT_URL"
```

#### Step 4: Monitor via CloudWatch Synthetics
- Navigate to CloudWatch → Synthetics → Canaries
- View detailed monitoring data, screenshots, and logs
- Check the automatically created dashboard for performance metrics


## Customization

### Variables
Edit `terraform/terraform.tfvars` to customize:
- AWS region
- Project name
- Environment name
- VPC CIDR block
- Container port
- Health check path

**Example terraform.tfvars:**
```hcl
# AWS Configuration
aws_region = "us-west-2"

# Project Configuration
project_name = "my-website-monitor"
environment  = "prod"

# Network Configuration
vpc_cidr = "172.16.0.0/16"

# Application Configuration
container_port      = 80
health_check_path   = "/health"
```

### Website Content
Modify files in `website/src/` to customize the website:
- `index.html` - Main content and structure
- `styles.css` - Styling and responsive design
- `script.js` - Interactive functionality

```hcl
# CloudWatch Synthetics Canary with Custom Script
resource "aws_synthetics_canary" "website" {
  name                 = "${var.project_name}-canary"
  artifact_s3_location = "s3://${aws_s3_bucket.synthetics.bucket}/"
  execution_role_arn   = aws_iam_role.synthetics.arn
  runtime_version      = "syn-nodejs-puppeteer-6.2"
  handler              = "index.handler"

  # Uses a custom script uploaded to S3
  s3_bucket = aws_s3_bucket.synthetics.bucket
  s3_key    = aws_s3_object.canary_zip.key

  schedule {
    expression = "rate(5 minutes)"  # Adjust frequency here
  }

  run_config {
    timeout_in_seconds = 60
    environment_variables = {
      URL = var.website_url  # CloudFront URL to monitor
    }
  }

  success_retention_period = 2  # Days to retain successful test artifacts
  failure_retention_period = 10 # Days to retain failed test artifacts
}

```
## Cleanup

To destroy all resources:
```bash
cd terraform
terraform destroy
```
## Troubleshooting

### Common Issues

1. **ECR Image Not Found Error:**
   - Make sure you've pushed the Docker image to ECR first

2. **ECS Service Won't Start:**
   - Check CloudWatch logs: `/ecs/cloudwatch-synthetics-demo`
   - Verify security groups allow traffic on port 80
   - Ensure ECR image exists and is accessible

3. **Website Not Accessible:**
   - Wait 2-3 minutes for ECS tasks to be running
   - Check ALB target group health in AWS Console
   - Verify security groups allow inbound traffic on port 80

4. **CloudWatch Synthetics Failures:**
   - Check the screenshots to identify visual issues
   - Review HTTP status codes for server-side problems
   - Examine step duration metrics for performance bottlenecks
   - Verify the canary has proper permissions to access your website

5. **Terraform Apply Fails:**
   - Check AWS credentials and permissions
   - Ensure you have permissions for ECS, ECR, ALB, VPC, IAM, CloudWatch
   - Try applying specific modules first: `terraform apply -target=module.networking`

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster cloudwatch-synthetics-demo-cluster --services cloudwatch-synthetics-demo-service

# Check ECS task logs
aws logs tail /ecs/cloudwatch-synthetics-demo --follow

# List ECR images
aws ecr list-images --repository-name cloudwatch-synthetics-demo-website

# Force ECS service update
aws ecs update-service --cluster cloudwatch-synthetics-demo-cluster --service cloudwatch-synthetics-demo-service --force-new-deployment

# Get CloudWatch Synthetics canary status
aws synthetics get-canary --name cloudwatch-synthetics-demo-canary

# View recent canary runs
aws synthetics list-canary-runs --name cloudwatch-synthetics-demo-canary
```

## Cost Optimization

This project is designed to be cost-effective:
- Uses ECS Fargate (pay per use)
- Minimal resource allocation (256 CPU, 512 MB memory)
- CloudWatch Synthetics runs every 5 minutes (configurable)
- S3 bucket for synthetics artifacts with lifecycle policies
- CloudWatch logs retention set to 7 days
