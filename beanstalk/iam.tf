data "aws_iam_policy_document" "sellix-web-app-default-policy-document" {
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

data "aws_iam_policy_document" "sellix-web-app-elb-policy-document" {
  statement {
    sid = ""
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${local.tags["Project"]}-${var.aws_region}-elb-logs/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [join("", data.aws_elb_service_account.sellix-web-app-elb-service.*.arn)]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "sellix-web-app-service-policy-document" {
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

data "aws_iam_policy_document" "sellix-web-app-service-sns-policy-document" {
  statement {
    sid = ""
    actions = [
      "sns:Publish"
    ]
    resources = [
      data.terraform_remote_state.sellix-web-app-chatbot-terraform-state.outputs["${var.aws_region}_chatbot-arn"],
      "arn:aws:sns:eu-west-1:671586216466:ElasticBeanstalkNotifications*"
    ]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "sellix-web-app-ec2-policy-document" {
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

data "aws_iam_policy_document" "sellix-web-app-codebuild-policy-document" {
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
      aws_s3_bucket.sellix-web-app-codepipeline-s3-bucket.arn,
      "${aws_s3_bucket.sellix-web-app-codepipeline-s3-bucket.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "sellix-web-app-codebuild-codestar-connection-policy-document" {
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection"
    ]
    resources = [
      var.codestar_connection_arn
    ]
  }
}

data "aws_iam_policy_document" "sellix-web-app-codebuild-assumerole-policy-document" {
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

data "aws_iam_policy_document" "sellix-web-app-codebuild-permissions-policy-document" {
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

data "aws_elb_service_account" "sellix-web-app-elb-service" {
  count = 1
}

resource "aws_iam_role" "sellix-web-app-codepipeline-role" {
  name               = "${local.tags["Project"]}-${var.aws_region}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-web-app-service-policy-document.json
}

resource "aws_iam_role" "sellix-web-app-service-role" {
  name               = "${local.tags["Project"]}-${var.aws_region}-service-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-web-app-service-policy-document.json
}

resource "aws_iam_role" "sellix-web-app-ec2-role" {
  name               = "${local.tags["Project"]}-${var.aws_region}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-web-app-ec2-policy-document.json
}

resource "aws_iam_instance_profile" "sellix-web-app-ec2-instance-profile" {
  name = "${local.tags["Project"]}-${var.aws_region}-ec2-instance-profile"
  role = aws_iam_role.sellix-web-app-ec2-role.name
}

resource "aws_iam_role_policy" "sellix-web-app-codepipeline-policy" {
  name   = "${local.tags["Project"]}-${var.aws_region}-codepipeline-policy"
  role   = aws_iam_role.sellix-web-app-codepipeline-role.id
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
        "${aws_s3_bucket.sellix-web-app-codepipeline-s3-bucket.arn}",
        "${aws_s3_bucket.sellix-web-app-codepipeline-s3-bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:*"
      ],
      "Resource": [
        "${var.codestar_connection_arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "sellix-web-app-service-sns-policy" {
  name   = "${local.tags["Project"]}-${var.aws_region}-service-sns-policy"
  role   = aws_iam_role.sellix-web-app-service-role.id
  policy = data.aws_iam_policy_document.sellix-web-app-service-sns-policy-document.json
}

resource "aws_iam_role_policy" "sellix-web-app-default-policy" {
  name   = "${local.tags["Project"]}-${var.aws_region}-default-policy"
  role   = aws_iam_role.sellix-web-app-ec2-role.id
  policy = data.aws_iam_policy_document.sellix-web-app-default-policy-document.json
}

resource "aws_iam_role" "sellix-web-app-codebuild-role" {
  name               = "${local.tags["Project"]}-${var.aws_region}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-web-app-codebuild-assumerole-policy-document.json
}

resource "aws_iam_policy" "sellix-web-app-codebuild-permissions-policy" {
  name   = "${local.tags["Project"]}-${var.aws_region}-codebuild-permissions-policy"
  path   = "/service-role/"
  policy = data.aws_iam_policy_document.sellix-web-app-codebuild-permissions-policy-document.json
}

resource "aws_iam_policy" "sellix-web-app-codebuild-policy" {
  name        = "${local.tags["Project"]}-${var.aws_region}-codebuild-policy"
  description = "CodeBuild access policy"
  policy      = data.aws_iam_policy_document.sellix-web-app-codebuild-policy-document.json
}

resource "aws_iam_policy" "sellix-web-app-codebuild-codestar-connection-policy" {
  name        = "${local.tags["Project"]}-${var.aws_region}-codebuild-codestar-connection-policy"
  description = "CodeBuild CodeStar Connection policy"
  policy      = data.aws_iam_policy_document.sellix-web-app-codebuild-codestar-connection-policy-document.json
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-codepipeline-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-AWSElasticBeanstalk"
  role       = aws_iam_role.sellix-web-app-codepipeline-role.id
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-enhanced-health-policy-attachment" {
  role       = aws_iam_role.sellix-web-app-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-service-policy-attachment" {
  role       = aws_iam_role.sellix-web-app-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-docker-policy-attachment" {
  role       = aws_iam_role.sellix-web-app-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-web-tier-policy-attachment" {
  role       = aws_iam_role.sellix-web-app-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-worker-tier-policy-attachment" {
  role       = aws_iam_role.sellix-web-app-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-ssm-ec2-policy-attachment" {
  role       = aws_iam_role.sellix-web-app-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-ssm-automation-policy-attachment" {
  role       = aws_iam_role.sellix-web-app-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-codebuild-policy-attachment" {
  role       = aws_iam_role.sellix-web-app-codebuild-role.name
  policy_arn = aws_iam_policy.sellix-web-app-codebuild-policy.arn
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-codebuild-codestar-connection-policy-attachment" {
  role       = aws_iam_role.sellix-web-app-codebuild-role.name
  policy_arn = aws_iam_policy.sellix-web-app-codebuild-codestar-connection-policy.arn
}

resource "aws_iam_role_policy_attachment" "sellix-web-app-codebuild-permissions-policy-attachment" {
  role       = aws_iam_role.sellix-web-app-codebuild-role.name
  policy_arn = aws_iam_policy.sellix-web-app-codebuild-permissions-policy.arn
}