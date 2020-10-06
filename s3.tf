resource "aws_s3_bucket" "web-app-codepipeline-s3-bucket" {
  bucket = "sellix-web-app-${var.environment_check}-codepipeline"
  acl    = "private"
  tags   = local.tags
}