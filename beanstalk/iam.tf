data "aws_iam_policy_document" "sellix-eb-default-policy-document" {
  statement {
    sid = "EBRequirements"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeNotificationConfigurations",
      "autoscaling:AttachInstances",
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:CreateLaunchConfiguration",
      "autoscaling:DeleteLaunchConfiguration",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DeleteScheduledAction",
      "autoscaling:DescribeAccountLimits",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeLoadBalancers",
      "autoscaling:DescribeNotificationConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeScheduledActions",
      "autoscaling:DetachInstances",
      "autoscaling:PutScheduledUpdateGroupAction",
      "autoscaling:ResumeProcesses",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:SetInstanceProtection",
      "autoscaling:SuspendProcesses",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:GetConsoleOutput",
      "ec2:AssociateAddress",
      "ec2:DescribeAddresses",
      "ec2:DescribeSecurityGroups",
      "ec2:AssociateAddress",
      "ec2:AllocateAddress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DisassociateAddress",
      "ec2:ReleaseAddress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:TerminateInstances",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "iam:ListRoles",
      "iam:PassRole",
      "codebuild:CreateProject",
      "codebuild:DeleteProject",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "cloudwatch:PutMetricAlarm",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "BucketAccess"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::elasticbeanstalk-*",
      "arn:aws:s3:::elasticbeanstalk-*/*"
    ]
  }
  /* statement {
    sid = "XRayAccess"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]
    effect   = "Allow"
    resources = ["*"]
  }*/
  statement {
    sid = "CloudWatchLogsAccess"
    actions = [
      "logs:PutRetentionPolicy",
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/elasticbeanstalk*"
    ]
  }
  statement {
    sid = "ElasticBeanstalkHealthAccess"
    actions = [
      "elasticbeanstalk:*"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:elasticbeanstalk:*:*:application/*",
      "arn:aws:elasticbeanstalk:*:*:environment/*"
    ]
  }
}

/* data "aws_iam_policy_document" "sellix-eb-default-policy-document" {
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
} */

data "aws_iam_policy_document" "sellix-eb-elb-policy-document" {
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
      identifiers = [join("", data.aws_elb_service_account.sellix-eb-elb-service.*.arn)]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "sellix-eb-service-policy-document" {
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

data "aws_iam_policy_document" "sellix-eb-service-sns-policy-document" {
  statement {
    sid = ""
    actions = [
      "sns:Publish"
    ]
    resources = [
      data.terraform_remote_state.sellix-eb-chatbot-terraform-state.outputs["${var.aws_region}_chatbot-arn"],
      "arn:aws:sns:eu-west-1:671586216466:ElasticBeanstalkNotifications*"
    ]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "sellix-eb-ec2-policy-document" {
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

data "aws_iam_policy_document" "sellix-eb-codebuild-policy-document" {
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
      aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.arn,
      "${aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "sellix-eb-codebuild-codestar-connection-policy-document" {
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

data "aws_iam_policy_document" "sellix-eb-codebuild-assumerole-policy-document" {
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

data "aws_iam_policy_document" "sellix-eb-codebuild-permissions-policy-document" {
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

data "aws_iam_policy_document" "sellix-eb-codepipeline-s3-permissions-policy-document" {
  statement {
    sid = ""
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.arn,
      "${aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "sellix-eb-codepipeline-codebuild-permissions-policy-document" {
  statement {
    sid = ""
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    effect = "Allow"
    resources = [
      aws_codebuild_project.sellix-eb.arn
    ]
  }
}

data "aws_iam_policy_document" "sellix-eb-codepipeline-codestar-permissions-policy-document" {
  statement {
    sid = ""
    actions = [
      "codestar-connections:*"
    ]
    effect = "Allow"
    resources = [
      var.codestar_connection_arn
    ]
  }
}

data "aws_elb_service_account" "sellix-eb-elb-service" {
  count = 1
}

resource "aws_iam_role" "sellix-eb-codepipeline-role" {
  name               = "${local.tags["Project"]}-${var.aws_region}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-eb-service-policy-document.json
}

resource "aws_iam_role" "sellix-eb-service-role" {
  name               = "${local.tags["Project"]}-${var.aws_region}-service-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-eb-service-policy-document.json
}

resource "aws_iam_role" "sellix-eb-ec2-role" {
  name               = "${local.tags["Project"]}-${var.aws_region}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-eb-ec2-policy-document.json
}

resource "aws_iam_instance_profile" "sellix-eb-ec2-instance-profile" {
  name = "${local.tags["Project"]}-${var.aws_region}-ec2-instance-profile"
  role = aws_iam_role.sellix-eb-ec2-role.name
}

resource "aws_iam_role_policy" "sellix-eb-service-sns-policy" {
  name   = "${local.tags["Project"]}-${var.aws_region}-service-sns-policy"
  role   = aws_iam_role.sellix-eb-service-role.id
  policy = data.aws_iam_policy_document.sellix-eb-service-sns-policy-document.json
}

resource "aws_iam_role_policy" "sellix-eb-default-policy" {
  name   = "${local.tags["Project"]}-${var.aws_region}-default-policy"
  role   = aws_iam_role.sellix-eb-ec2-role.id
  policy = data.aws_iam_policy_document.sellix-eb-default-policy-document.json
}

resource "aws_iam_role" "sellix-eb-codebuild-role" {
  name               = "${local.tags["Project"]}-${var.aws_region}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-eb-codebuild-assumerole-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codebuild-permissions-policy" {
  name   = "${local.tags["Project"]}-${var.aws_region}-codebuild-permissions-policy"
  path   = "/service-role/"
  policy = data.aws_iam_policy_document.sellix-eb-codebuild-permissions-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codebuild-policy" {
  name        = "${local.tags["Project"]}-${var.aws_region}-codebuild-policy"
  description = "CodeBuild access policy"
  policy      = data.aws_iam_policy_document.sellix-eb-codebuild-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codebuild-codestar-connection-policy" {
  name        = "${local.tags["Project"]}-${var.aws_region}-codebuild-codestar-connection-policy"
  description = "CodeBuild CodeStar Connection policy"
  policy      = data.aws_iam_policy_document.sellix-eb-codebuild-codestar-connection-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codepipeline-s3-permissions-policy" {
  name   = "${local.tags["Project"]}-${var.aws_region}-codepipeline-s3-permissions-policy"
  policy = data.aws_iam_policy_document.sellix-eb-codepipeline-s3-permissions-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codepipeline-codebuild-permissions-policy" {
  name   = "${local.tags["Project"]}-${var.aws_region}-codepipeline-codebuild-permissions-policy"
  policy = data.aws_iam_policy_document.sellix-eb-codepipeline-codebuild-permissions-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codepipeline-codestar-permissions-policy" {
  name   = "${local.tags["Project"]}-${var.aws_region}-codepipeline-codestar-permissions-policy"
  policy = data.aws_iam_policy_document.sellix-eb-codepipeline-codestar-permissions-policy-document.json
}

resource "aws_iam_role_policy_attachment" "sellix-eb-codepipeline-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-AWSElasticBeanstalk"
  role       = aws_iam_role.sellix-eb-codepipeline-role.id
}

resource "aws_iam_role_policy_attachment" "sellix-eb-enhanced-health-policy-attachment" {
  role       = aws_iam_role.sellix-eb-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "sellix-eb-service-policy-attachment" {
  role       = aws_iam_role.sellix-eb-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_role_policy_attachment" "sellix-eb-web-tier-policy-attachment" {
  role       = aws_iam_role.sellix-eb-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "sellix-eb-worker-tier-policy-attachment" {
  role       = aws_iam_role.sellix-eb-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "sellix-eb-ssm-ec2-policy-attachment" {
  role       = aws_iam_role.sellix-eb-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "sellix-eb-codebuild-policy-attachment" {
  role       = aws_iam_role.sellix-eb-codebuild-role.name
  policy_arn = aws_iam_policy.sellix-eb-codebuild-policy.arn
}

resource "aws_iam_role_policy_attachment" "sellix-eb-codebuild-codestar-connection-policy-attachment" {
  role       = aws_iam_role.sellix-eb-codebuild-role.name
  policy_arn = aws_iam_policy.sellix-eb-codebuild-codestar-connection-policy.arn
}

resource "aws_iam_role_policy_attachment" "sellix-eb-codebuild-permissions-policy-attachment" {
  role       = aws_iam_role.sellix-eb-codebuild-role.name
  policy_arn = aws_iam_policy.sellix-eb-codebuild-permissions-policy.arn
}

resource "aws_iam_role_policy_attachment" "sellix-eb-codepipeline-s3-permissions-policy-attachment" {
  role       = aws_iam_role.sellix-eb-codepipeline-role.name
  policy_arn = aws_iam_policy.sellix-eb-codepipeline-s3-permissions-policy.arn
}

resource "aws_iam_role_policy_attachment" "sellix-eb-codepipeline-codebuild-permissions-policy-attachment" {
  role       = aws_iam_role.sellix-eb-codepipeline-role.name
  policy_arn = aws_iam_policy.sellix-eb-codepipeline-codebuild-permissions-policy.arn
}

resource "aws_iam_role_policy_attachment" "sellix-eb-codepipeline-codestar-permissions-policy-attachment" {
  role       = aws_iam_role.sellix-eb-codepipeline-role.name
  policy_arn = aws_iam_policy.sellix-eb-codepipeline-codestar-permissions-policy.arn
}
