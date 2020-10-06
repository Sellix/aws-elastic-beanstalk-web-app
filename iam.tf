data "aws_iam_policy_document" "web-app-default-policy-document" {
  statement {
    sid = ""
    actions = [
      "elasticbeanstalk:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "cloudformation:*",
      "rds:*",
      "sqs:*",
      "ecs:*",
      "iam:PassRole",
      "logs:PutRetentionPolicy",
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "web-app-service-policy-document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com", "codepipeline.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "web-app-ec2-policy-document" {
  statement {
    sid = ""
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    effect = "Allow"
  }
  statement {
    sid = ""
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
    resources = [
      "${aws_s3_bucket.web-app-codepipeline-s3-bucket.arn}",
      "${aws_s3_bucket.web-app-codepipeline-s3-bucket.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_assumerole" {
  statement {
    sid    = "AllowCodeBuildAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "codebuild.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "codebuild-permissions" {
  statement {
    sid = ""
    actions = [
      "codecommit:GitPull",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecs:RunTask",
      "iam:PassRole",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
    ]
    effect = "Allow"
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "web-app-codepipeline-role" {
  name               = "sellix-web-app-${var.environment_check}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.web-app-service-policy-document.json
}

resource "aws_iam_role" "web-app-service-role" {
  name               = "sellix-web-app-${var.environment_check}-service-role"
  assume_role_policy = data.aws_iam_policy_document.web-app-service-policy-document.json
}

resource "aws_iam_role" "web-app-ec2-role" {
  name               = "sellix-web-app-${var.environment_check}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.web-app-ec2-policy-document.json
}

resource "aws_iam_instance_profile" "web-app-ec2-instance-profile" {
  name = "sellix-web-app-${var.environment_check}-ec2-instance-profile"
  role = aws_iam_role.web-app-ec2-role.name
}

resource "aws_iam_role_policy" "web-app-codepipeline-policy" {
  name = "sellix-web-app-${var.environment_check}-codepipeline-policy"
  role = aws_iam_role.web-app-codepipeline-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.web-app-codepipeline-s3-bucket.arn}",
        "${aws_s3_bucket.web-app-codepipeline-s3-bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "web-app-default-policy" {
  name   = "sellix-web-app-${var.environment_check}-default-policy"
  role   = aws_iam_role.web-app-ec2-role.id
  policy = data.aws_iam_policy_document.web-app-default-policy-document.json
}

resource "aws_iam_role_policy_attachment" "web-app-codepipeline-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkFullAccess"
  role       = aws_iam_role.web-app-codepipeline-role.id
}

resource "aws_iam_role_policy_attachment" "web-app-enhanced-health-policy-attachment" {
  role       = aws_iam_role.web-app-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "web-app-service-policy-attachment" {
  role       = aws_iam_role.web-app-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_role_policy_attachment" "web-app-docker-policy-attachment" {
  role       = aws_iam_role.web-app-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "web-app-web-tier-policy-attachment" {
  role       = aws_iam_role.web-app-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "web-app-worker-tier-policy-attachment" {
  role       = aws_iam_role.web-app-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "web-app-ssm-ec2-policy-attachment" {
  role       = aws_iam_role.web-app-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "web-app-ssm-automation-policy-attachment" {
  role       = aws_iam_role.web-app-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "web-app-${var.environment_check}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assumerole.json
}

resource "aws_iam_policy" "codebuild-permissions" {
  name   = "sellix-web-app-${var.environment_check}-codebuild-permissions"
  path   = "/service-role/"
  policy = data.aws_iam_policy_document.codebuild-permissions.json
}

resource "aws_iam_policy" "codebuild" {
  name        = "sellix-web-app-${var.environment_check}-codebuild"
  description = "CodeBuild access policy"
  policy      = data.aws_iam_policy_document.codebuild.json
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

resource "aws_iam_role_policy_attachment" "codebuild-permissions" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild-permissions.arn
}