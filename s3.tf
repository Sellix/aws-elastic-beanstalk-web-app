resource "aws_s3_bucket" "sellix-web-app-codepipeline-s3-bucket" {
  bucket = "sellix-web-app-${terraform.workspace}-codepipeline"
  acl    = "private"
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-codepipeline-s3-bucket"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
}

resource "aws_s3_bucket" "sellix-web-app-elb-logs" {
  bucket = "sellix-web-app-${terraform.workspace}-elb-logs"
  acl    = "private"
  policy = join("", data.aws_iam_policy_document.sellix-web-app-elb-policy-document.*.json)
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-elb-logs"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
}