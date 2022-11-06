resource "aws_s3_bucket" "sellix-eb-codepipeline-s3-bucket" {
  bucket = "${local.tags["Project"]}-${var.aws_region}-codepipeline"
  tags = merge({
    "Name" = "${local.tags["Project"]}-${var.aws_region}-codepipeline-s3-bucket"
    },
    local.tags
  )
}

resource "aws_s3_bucket_acl" "sellix-eb-codepipeline-s3-bucket-acl" {
  bucket = aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.id
  acl    = "private"
}

resource "aws_s3_bucket" "sellix-eb-elb-logs" {
  bucket = "${local.tags["Project"]}-${var.aws_region}-elb-logs"
  tags = merge({
    "Name" = "${local.tags["Project"]}-${var.aws_region}-elb-logs"
    },
    local.tags
  )
}

resource "aws_s3_bucket_policy" "sellix-eb-elb-logs-policy" {
  bucket = aws_s3_bucket.sellix-eb-elb-logs.id
  policy = join("", data.aws_iam_policy_document.sellix-eb-elb-policy-document[*].json)
}

resource "aws_s3_bucket_acl" "sellix-eb-elb-logs-acl" {
  bucket = aws_s3_bucket.sellix-eb-elb-logs.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "sellix-eb-codepipeline-s3-bucket-public-access-block" {
  bucket                  = aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_public_access_block" "sellix-eb-elb-logs-public-access-block" {
  bucket                  = aws_s3_bucket.sellix-eb-elb-logs.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}
