resource "aws_s3_bucket" "sellix-web-app-codepipeline-bucket" {
  bucket = "sellix-web-app-codepipeline-bucket"
  acl    = "private"
}