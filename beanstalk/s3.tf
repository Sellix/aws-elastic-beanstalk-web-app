// https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up.html#setting-up-kms
// s3 + ecr kms key
data "aws_iam_policy_document" "sellix-kms-key-usage" {
  statement {
    sid       = "AllowRoot"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.aws_account_id}:root"]
    }
  }

  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${local.aws_region}.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [local.aws_account_id]
    }
  }

  statement {
    sid    = "AllowCodeBuild"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.sellix-eb-codebuild-role.arn]
    }
  }
}

resource "aws_kms_key" "sellix-eb-kms-key" {
  description         = "ElasticBeanstalk ${var.tags["Project"]} Key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.sellix-kms-key-usage.json
  tags = merge(
    {
      Name = "${var.tags["Project"]}-kms-key"
    },
    var.tags
  )
}

resource "aws_kms_alias" "sellix-eb-kms-alias" {
  name          = "alias/${var.tags["Project"]}"
  target_key_id = aws_kms_key.sellix-eb-kms-key.id
}

resource "aws_s3_bucket" "sellix-eb-codepipeline-s3-bucket" {
  bucket = "${var.tags["Project"]}-${local.aws_region}-codepipeline"
  tags = merge({
    "Name" = "${var.tags["Project"]}-${local.aws_region}-codepipeline-s3-bucket"
    },
    var.tags
  )
}

resource "aws_s3_bucket" "sellix-eb-elb-logs" {
  count = var.is_production ? 1 : 0

  bucket = "${var.tags["Project"]}-${local.aws_region}-elb-logs"
  tags = merge(
    {
      "Name" = "${var.tags["Project"]}-${local.aws_region}-elb-logs"
    },
    var.tags
  )
}

resource "aws_s3_bucket_policy" "sellix-eb-elb-logs-policy" {
  for_each = toset(aws_s3_bucket.sellix-eb-elb-logs[*].id)

  bucket = each.value
  policy = join("", data.aws_iam_policy_document.sellix-eb-elb-policy-document[*].json)
}

resource "aws_s3_bucket_public_access_block" "sellix-eb-codepipeline-s3-bucket-public-access-block" {
  bucket                  = aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_public_access_block" "sellix-eb-elb-logs-public-access-block" {
  for_each = toset(aws_s3_bucket.sellix-eb-elb-logs[*].id)

  bucket                  = each.value
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sellix-eb-codepipeline-s3-bucket-sse-config" {
  bucket = aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.sellix-eb-kms-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sellix-eb-elb-logs-s3-bucket-sse-config" {
  for_each = toset(aws_s3_bucket.sellix-eb-elb-logs[*].id)
  bucket   = each.value

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
