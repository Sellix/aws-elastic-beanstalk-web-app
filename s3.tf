resource "aws_s3_bucket" "web-app-codepipeline-s3-bucket" {
  bucket = "sellix-web-app-codepipeline"
  acl    = "private"
}