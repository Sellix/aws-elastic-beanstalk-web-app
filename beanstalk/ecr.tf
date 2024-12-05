/*
    https://docs.aws.amazon.com/AmazonECR/latest/userguide/replication.html
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_replication_configuration
*/

resource "aws_ecr_repository" "sellix-ecr" {
  for_each             = var.ecr_enabled ? toset(local.docker_environments) : []
  name                 = "${var.tags["Project"]}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.sellix-eb-kms-key.arn
  }
  tags = merge({
    Name = "${var.tags["Project"]}-${each.key}"
    },
    var.tags
  )
}

resource "aws_ecr_lifecycle_policy" "sellix-ecr-policy" {
  for_each   = aws_ecr_repository.sellix-ecr
  repository = each.value.name

  policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep last 10 images",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : 10
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "sellix-ecr-policy-document" {
  statement {
    sid    = "AllowCodeBuildPush"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.sellix-eb-codebuild-role.arn]
    }
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
  }

  statement {
    sid    = "AllowBeanstalkPull"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.sellix-eb-service-role.arn]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
  }
}

resource "aws_ecr_repository_policy" "sellix-ecr-policy" {
  for_each   = aws_ecr_repository.sellix-ecr
  repository = each.value.name
  policy     = data.aws_iam_policy_document.sellix-ecr-policy-document.json
}