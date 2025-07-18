# IAM Role for CloudWatch Synthetics
resource "aws_iam_role" "synthetics" {
  name = "${var.project_name}-synthetics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "synthetics.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-synthetics-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "synthetics" {
  role       = aws_iam_role.synthetics.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchSyntheticsFullAccess"
}
resource "aws_iam_role_policy_attachment" "cw_full_access" {
  role       = aws_iam_role.synthetics.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.synthetics.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# S3 Bucket for Synthetics artifacts
resource "aws_s3_bucket" "synthetics" {
  bucket        = "${var.project_name}-synthetics-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-synthetics"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "synthetics" {
  bucket = aws_s3_bucket.synthetics.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}


resource "aws_s3_object" "canary_zip" {
  bucket = aws_s3_bucket.synthetics.bucket
  key    = "canary/heartbeat.zip"
source = "${path.module}/canary.zip"
}

resource "aws_synthetics_canary" "website" {
  name                 = "${var.project_name}-canary"
  artifact_s3_location = "s3://${aws_s3_bucket.synthetics.bucket}/"
  execution_role_arn   = aws_iam_role.synthetics.arn
  runtime_version      = "syn-nodejs-puppeteer-6.2"
  handler              = "index.handler"

  # Use a source location from S3
  s3_bucket = aws_s3_bucket.synthetics.bucket
  s3_key    = aws_s3_object.canary_zip.key

  schedule {
    expression = "rate(5 minutes)"
  }

  run_config {
    timeout_in_seconds = 60
    environment_variables = {
      URL = var.website_url
    }
  }

  depends_on               = [aws_s3_object.canary_zip]
  success_retention_period = 2
  failure_retention_period = 10

  tags = {
    Name        = "${var.project_name}-canary"
    Environment = var.environment
  }
}

# CloudWatch Alarm for Canary
resource "aws_cloudwatch_metric_alarm" "website_availability" {
  alarm_name          = "${var.project_name}-website-availability"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors website availability"
  alarm_actions       = []

  dimensions = {
    CanaryName = aws_synthetics_canary.website.name
  }

  tags = {
    Name        = "${var.project_name}-availability-alarm"
    Environment = var.environment
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "website" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["CloudWatchSynthetics", "SuccessPercent", "CanaryName", aws_synthetics_canary.website.name],
            [".", "Duration", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Website Monitoring"
          period  = 300
        }
      }
    ]
  })
}
