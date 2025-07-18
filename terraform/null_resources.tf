resource "null_resource" "combined_cleanup" {
  triggers = {
    s3_bucket_name = module.monitoring.s3_bucket_name
    aws_region     = var.aws_region
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["cmd", "/C"]
    command     = "aws s3 rm s3://${self.triggers.s3_bucket_name} --recursive --region ${self.triggers.aws_region} || echo S3 bucket already empty or deleted"
  }


  depends_on = [
    module.monitoring,
  ]
}
