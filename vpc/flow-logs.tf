resource "aws_flow_log" "sellix-eb-vpc-flow-log" {
  log_destination          = aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.arn
  log_destination_type     = "s3"
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.sellix-eb-vpc.id
  max_aggregation_interval = 600

  destination_options {
    file_format = "parquet"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.tags["Project"]}-vpc-flow-logs"
    }
  )
}

resource "aws_s3_bucket" "sellix-eb-vpc-flow-log-bucket" {
  bucket = "${var.tags["Project"]}-${local.aws_region}-vpc-flow-logs-bucket"

  tags = merge(
    {
      Name = "${var.tags["Project"]}-${local.aws_region}-vpc-flow-logs-bucket"
    },
    var.tags
  )
}

data "aws_iam_policy_document" "sellix-eb-vpc-flow-log-kms-key-usage" {
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
    sid    = "AllowLogsDelivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${local.aws_region}:${local.aws_account_id}:*"]
    }
  }
}

resource "aws_kms_key" "sellix-eb-vpc-flow-log-kms-key" {
  description         = "ElasticBeanstalk ${var.tags["Project"]} VPC Flow Logs Key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.sellix-eb-vpc-flow-log-kms-key-usage.json
  tags = merge(
    {
      Name = "${var.tags["Project"]}-${local.aws_region}-vpc-flow-log-kms-key"
    },
    var.tags
  )
}

resource "aws_kms_alias" "sellix-eb-kms-alias" {
  name          = "alias/${var.tags["Project"]}-${local.aws_region}-vpc-flow-log-key"
  target_key_id = aws_kms_key.sellix-eb-vpc-flow-log-kms-key.id
}

data "aws_iam_policy_document" "sellix-eb-vpc-flow-log-bucket-policy-document" {
  statement {
    sid    = "DenyObjectsThatAreNotSSEKMS"
    effect = "Deny"
    resources = [
      aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.arn,
      "${aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.arn}/*"
    ]
    actions = ["s3:PutObject"]

    condition {
      test     = "StringNotEqualsIfExists"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    sid    = "DenyUnauthorizedKmsKeys"
    effect = "Deny"
    resources = [
      aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.arn,
      "${aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.arn}/*"
    ]
    actions = ["s3:PutObject"]

    condition {
      test     = "ArnNotEqualsIfExists"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.sellix-eb-vpc-flow-log-kms-key.arn]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.arn}/AWSLogs/${local.aws_account_id}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${local.aws_region}:${local.aws_account_id}:*"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryAclCheck"
    effect    = "Allow"
    resources = [aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.arn]
    actions   = ["s3:GetBucketAcl"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${local.aws_region}:${local.aws_account_id}:*"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "sellix-eb-vpc-flow-log-bucket-policy" {
  bucket = aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.id
  policy = data.aws_iam_policy_document.sellix-eb-vpc-flow-log-bucket-policy-document.json
}

resource "aws_s3_bucket_public_access_block" "sellix-eb-vpc-flow-log-bucket-public-access-block" {
  bucket                  = aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sellix-eb-vpc-flow-log-bucket-sse-config" {
  bucket = aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.sellix-eb-vpc-flow-log-kms-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "sellix-eb-vpc-flow-log-bucket-lifecycle-rules" {
  bucket = aws_s3_bucket.sellix-eb-vpc-flow-log-bucket.id

  rule {
    id = "expire-vpc-flow-log-90d"

    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }

    filter {
      prefix = "AWSLogs/${local.aws_account_id}/vpcflowlogs/"
    }

    expiration {
      days = 90
    }

    status = "Enabled"
  }
}
