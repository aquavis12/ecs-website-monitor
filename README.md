# ECS Website Monitor Project

A complete AWS infrastructure project that deploys a static website about Cloud and AI using CloudFront, ALB, ECS, and **CloudWatch Synthetics** for advanced monitoring. Built with Terraform modules for infrastructure as code.

> **CloudWatch Synthetics Canary: The Star of the Show**  
> This project showcases the power of CloudWatch Synthetics Canaries for proactive monitoring, providing real-time insights into website availability and performance from an end-user perspective.

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
ecs-website-monitor/
├── terraform/
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Input variables (no defaults)
│   ├── terraform.tfvars      # Variable values
│   ├── null_resources.tf     # S3 cleanup logic
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
   CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)
   echo "Website URL: https://$CLOUDFRONT_URL"
   ```

5. **Monitor via CloudWatch Synthetics:**
   - Navigate to CloudWatch → Synthetics → Canaries
   - View detailed monitoring data, screenshots, and logs
   - Check the automatically created dashboard for performance metrics

## Terraform Modules

### Networking Module
- Creates VPC with public subnets across multiple AZs
- Sets up Internet Gateway and routing
- Configures security groups for ALB and ECS

### ECR Module
- Creates private ECR repository
- Configures lifecycle policies for image management
- Enables vulnerability scanning

### CloudFront Module
- Sets up global content delivery network
- Configures origin for ALB
- Optimizes caching and SSL settings
- Improves global performance and security

### ALB Module
- Sets up Application Load Balancer
- Configures target groups with health checks
- Creates security groups for web traffic

### ECS Module
- Creates ECS Fargate cluster with Container Insights
- Defines task definitions and services
- Sets up IAM roles and CloudWatch logging

### Monitoring Module - ⭐ The Star of the Show ⭐
- Creates CloudWatch Synthetics canary for website monitoring
- Sets up S3 bucket for synthetics artifacts
- Configures alarms and dashboards
- Provides end-to-end user experience monitoring
- Detects availability issues before your users do
- Captures screenshots for visual verification
- Measures critical performance metrics
- Enables historical trend analysis

## Features

- **Responsive Design:** Mobile-friendly static website about the project
- **Container-based Deployment:** Docker containerization with nginx
- **Global Content Delivery:** CloudFront CDN for low-latency access worldwide
- **High Availability:** Multi-AZ deployment with auto-scaling
- **Security:** Security groups, IAM roles, and least privilege access
- **Advanced Monitoring:** CloudWatch Synthetics for proactive testing
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

### CloudWatch Synthetics Configuration
Adjust monitoring settings in `terraform/modules/monitoring/main.tf`:
- **Canary Frequency**: Change the `rate(5 minutes)` expression to run tests more or less frequently
- **Runtime Version**: Update the runtime for newer features
- **Retention Periods**: Modify how long successful and failed test artifacts are stored
- **Alarm Thresholds**: Adjust when alerts are triggered based on availability percentage

```hcl
# CloudWatch Synthetics Canary
resource "aws_synthetics_canary" "website" {
  name                 = "${var.project_name}-canary"
  artifact_s3_location = "s3://${aws_s3_bucket.synthetics.bucket}/"
  execution_role_arn   = aws_iam_role.synthetics.arn
  handler              = "pageLoadBlueprint.handler"
  zip_file             = "pageLoadBlueprint.zip"
  runtime_version      = "syn-nodejs-puppeteer-6.2"

  schedule {
    expression = "rate(5 minutes)"  # Adjust frequency here
  }

  run_config {
    timeout_in_seconds = 60
  }

  success_retention_period = 2  # Days to retain successful test artifacts
  failure_retention_period = 10 # Days to retain failed test artifacts
}
```

## Viewing CloudWatch Synthetics Results

After deployment, you can access detailed monitoring data:

1. **Navigate to CloudWatch Synthetics Console**:
   - Go to AWS Console → CloudWatch → Synthetics → Canaries
   - Select your canary (named after your project)

2. **View Test Results**:
   - **Availability**: Percentage of successful tests
   - **Screenshots**: Visual captures of your website during tests
   - **Duration**: Load time metrics
   - **HTTP Status**: Response codes from your website
   - **Step Duration**: Breakdown of each test step's performance

3. **Analyze Trends**:
   - View historical data to identify performance patterns
   - Compare metrics across different time periods
   - Identify potential issues before they impact users

4. **Check Alarms**:
   - Review any triggered alarms
   - Adjust thresholds based on your requirements

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
aws ecs describe-services --cluster ecs-website-monitor-cluster --services ecs-website-monitor-service

# Check ECS task logs
aws logs tail /ecs/ecs-website-monitor --follow

# List ECR images
aws ecr list-images --repository-name ecs-website-monitor-website

# Force ECS service update
aws ecs update-service --cluster ecs-website-monitor-cluster --service ecs-website-monitor-service --force-new-deployment

# Get CloudWatch Synthetics canary status
aws synthetics get-canary --name ecs-website-monitor-canary

# View recent canary runs
aws synthetics list-canary-runs --name ecs-website-monitor-canary
```

## Cost Optimization

This project is designed to be cost-effective:
- Uses ECS Fargate (pay per use)
- Minimal resource allocation (256 CPU, 512 MB memory)
- CloudWatch Synthetics runs every 5 minutes (configurable)
- S3 bucket for synthetics artifacts with lifecycle policies
- CloudWatch logs retention set to 7 days
- CloudFront optimized for cost with PriceClass_100 (North America and Europe)