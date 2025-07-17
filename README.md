# ECS Website Monitor Project

A complete AWS infrastructure project that deploys a static website about Cloud and AI using ECS, ALB, ECR, and CloudWatch Synthetics for monitoring. Built with Terraform modules for infrastructure as code.

## Architecture

- **ECS Fargate** - Serverless container orchestration
- **Application Load Balancer** - Traffic distribution and health checks
- **ECR** - Private container registry
- **CloudWatch Synthetics** - Automated website monitoring
- **Nginx** - High-performance web server for static content
- **Terraform Modules** - Modular infrastructure as code

## Project Structure

```
ecs-website-monitor/
├── terraform/
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Input variables (no defaults)
│   ├── terraform.tfvars      # Variable values
│   ├── null_resources.tf     # S3 cleanup logic
│   ├── outputs.tf            # Output values
│   └── modules/
│       ├── networking/       # VPC, subnets, security groups
│       ├── ecr/             # Container registry
│       ├── alb/             # Application Load Balancer
│       ├── ecs/             # ECS cluster and services
│       └── monitoring/       # CloudWatch Synthetics
├── website/
│   ├── src/                 # Static website files
│   │   ├── index.html       # Main HTML page
│   │   ├── styles.css       # CSS styling
│   │   └── script.js        # JavaScript functionality
│   ├── Dockerfile           # Container definition
└── .gitignore               # Git ignore file
```

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Docker installed
- Terraform >= 1.0 installed

### Deployment Steps
1. **Clone and navigate to the project:**
   ```bash
   git clone https://github.com/aquavis12/ecs-website-monitor.git
   cd ecs-website-monitor
   ```

2. **Build and Push Docker Image to ECR:**
   
   ```bash
   # Navigate to website directory
   cd ../website
   
   # Get AWS account ID and region
   AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   AWS_REGION="us-east-1"  # or your preferred region
   
   # Login to ECR
   aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
   
   # Build the Docker image
   docker build -t ecs-website-monitor .
   
   # Tag the image for ECR
   docker tag ecs-website-monitor:latest $ECR_REPO:latest
   
   # Push the image to ECR
   docker push $ECR_REPO:latest
   ```
3. **Deploy Infrastructure:**
   ```bash
   terraform init
   terraform plan 
   terraform apply 
   ```

4. **Access your website:**
   ```bash
   cd terraform
   ALB_DNS=$(terraform output -raw alb_dns_name)
   echo "Website URL: http://$ALB_DNS"
   ```

5. **Monitor via CloudWatch:**
   - Check CloudWatch Synthetics for automated monitoring
   - View dashboards for performance metrics

## Terraform Modules

### Networking Module
- Creates VPC with public subnets across multiple AZs
- Sets up Internet Gateway and routing
- Configures security groups for ALB and ECS

### ECR Module
- Creates private ECR repository
- Configures lifecycle policies for image management
- Enables vulnerability scanning

### ALB Module
- Sets up Application Load Balancer
- Configures target groups with health checks
- Creates security groups for web traffic

### ECS Module
- Creates ECS Fargate cluster with Container Insights
- Defines task definitions and services
- Sets up IAM roles and CloudWatch logging

### Monitoring Module
- Creates CloudWatch Synthetics canary for website monitoring
- Sets up S3 bucket for synthetics artifacts
- Configures alarms and dashboards

## Features

- **Responsive Design:** Mobile-friendly static website about the project
- **Container-based Deployment:** Docker containerization with nginx
- **High Availability:** Multi-AZ deployment with auto-scaling
- **Security:** Security groups, IAM roles, and least privilege access
- **Monitoring:** Automated synthetic monitoring every 5 minutes
- **Infrastructure as Code:** Modular Terraform configuration


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

### Monitoring
Adjust monitoring settings in `terraform/modules/monitoring/`:
- Canary frequency
- Alarm thresholds
- Dashboard metrics

## Cleanup

To destroy all resources:
```bash
cd terraform
terraform destroy
```

**Note:** The infrastructure includes automatic S3 bucket cleanup during destroy phase. The null resource will:
- Remove all objects from the CloudWatch Synthetics S3 bucket
- Disable versioning if enabled
- Allow Terraform to successfully delete the bucket

This prevents the common issue where S3 buckets can't be deleted due to containing objects.

## Troubleshooting

### Common Issues

1. **ECR Image Not Found Error:**
   - Make sure you've pushed the Docker image to ECR first

2. **ECS Service Won't Start:**
   - Check CloudWatch logs: `/ecs/ecs-website-monitor`
   - Verify security groups allow traffic on port 80
   - Ensure ECR image exists and is accessible

3. **Website Not Accessible:**
   - Wait 2-3 minutes for ECS tasks to be running
   - Check ALB target group health in AWS Console
   - Verify security groups allow inbound traffic on port 80

4. **Terraform Apply Fails:**
   - Check AWS credentials and permissions
   - Ensure you have permissions for ECS, ECR, ALB, VPC, IAM, CloudWatch
   - Try applying specific modules first: `terraform apply -target=module.networking`

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster ecs-website-monitor-cluster --services ecs-website-monitor-service

# Check ECS task logs
aws logs tail /ecs/ecs-website-monitor --follow

# List ECR images
aws ecr list-images --repository-name ecs-website-monitor-website

# Force ECS service update
aws ecs update-service --cluster ecs-website-monitor-cluster --service ecs-website-monitor-service --force-new-deployment
```

## Cost Optimization

This project is designed to be cost-effective:
- Uses ECS Fargate (pay per use)
- Minimal resource allocation (256 CPU, 512 MB memory)
- CloudWatch Synthetics runs every 5 minutes
- S3 bucket for synthetics artifacts with lifecycle policies
- CloudWatch logs retention set to 7 days