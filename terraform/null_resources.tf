# Null resource to clean up S3 bucket during destroy
resource "null_resource" "s3_cleanup" {
  triggers = {
    bucket_name = module.monitoring.s3_bucket_name
    aws_region  = var.aws_region
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rm s3://${self.triggers.bucket_name} --recursive --region ${self.triggers.aws_region} || echo 'S3 bucket cleanup completed or bucket was already empty'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws s3api delete-bucket-versioning --bucket ${self.triggers.bucket_name} --versioning-configuration Status=Suspended --region ${self.triggers.aws_region} || echo 'Versioning already disabled or bucket does not exist'"
  }

  depends_on = [module.monitoring]
}