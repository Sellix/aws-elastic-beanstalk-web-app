/*
  see
  https://docs.aws.amazon.com/service-authorization/latest/reference/
*/

data "aws_iam_policy_document" "sellix-eb-service-req-policy-document" {
  statement {
    sid    = "ASGLaunchConfigPerms"
    effect = "Allow"
    actions = [
      "autoscaling:CreateLaunchConfiguration",
      "autoscaling:DeleteLaunchConfiguration",
    ]
    resources = [
      "arn:aws:autoscaling:*:*:launchConfiguration:*:launchConfigurationName/awseb-e-*",
      "arn:aws:autoscaling:*:*:launchConfiguration:*:launchConfigurationName/eb-*",
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/awseb-e-*",
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/eb-*"
    ]
  }

  statement {
    sid    = "ASGPerms"
    effect = "Allow"
    actions = [
      "autoscaling:AttachInstances",
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DeleteScheduledAction",
      "autoscaling:DetachInstances",
      "autoscaling:PutScheduledUpdateGroupAction",
      "autoscaling:ResumeProcesses",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:SetInstanceProtection",
      "autoscaling:SuspendProcesses",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:PutNotificationConfiguration",
    ]
    resources = [
      "arn:aws:autoscaling:*:*:launchConfiguration:*:launchConfigurationName/awseb-e-*",
      "arn:aws:autoscaling:*:*:launchConfiguration:*:launchConfigurationName/eb-*",
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/awseb-e-*",
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/eb-*"
    ]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/aws:cloudformation:stack-id"
      values = [
        "arn:aws:cloudformation:*:*:stack/awseb-e-*",
        "arn:aws:cloudformation:*:*:stack/eb-*"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/elasticbeanstalk:environment-name"
      values   = [for env_name, _ in var.environments : "${var.tags["Project"]}-${env_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Project"
      values   = [var.tags["Project"]]
    }
  }

  statement {
    sid    = "ELBReq"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/awseb-*",
      "arn:aws:elasticloadbalancing:*:*:targetgroup/eb-*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/awseb-*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/eb-*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/*/awseb-*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/*/eb-*/*"
    ]
  }

  statement {
    sid    = "TerminateInstanceReq"
    effect = "Allow"
    actions = [
      "ec2:TerminateInstances",
      "ec2:GetConsoleOutput" // enhanced health
    ]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/aws:cloudformation:stack-id"
      values = [
        "arn:aws:cloudformation:*:*:stack/awseb-e-*",
        "arn:aws:cloudformation:*:*:stack/eb-*"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/elasticbeanstalk:environment-name"
      values   = [for env_name, _ in var.environments : "${var.tags["Project"]}-${env_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Project"
      values   = [var.tags["Project"]]
    }
  }

  statement {
    sid    = "EBSGPerms"
    effect = "Allow"
    actions = [
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
      "ec2:ReleaseAddress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/aws:cloudformation:stack-id"
      values = [
        "arn:aws:cloudformation:*:*:stack/awseb-e-*",
        "arn:aws:cloudformation:*:*:stack/eb-*"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/elasticbeanstalk:environment-name"
      values   = [for env_name, _ in var.environments : "${var.tags["Project"]}-${env_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Project"
      values   = [var.tags["Project"]]
    }
  }

  statement {
    sid = "EBRequirements"
    actions = [
      "autoscaling:DescribeNotificationConfigurations",
      "autoscaling:DescribeAccountLimits",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeLoadBalancers",
      "autoscaling:DescribeScheduledActions",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:AllocateAddress",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTargetGroups",
      /*
      "iam:ListRoles",
      "codebuild:CreateProject",
      "codebuild:DeleteProject",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      */
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid    = "CWPutMetricAlarmOperationPermissions"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricAlarm"
    ]
    resources = [
      "arn:aws:cloudwatch:*:*:alarm:awseb-*",
      "arn:aws:cloudwatch:*:*:alarm:eb-*"
    ]
  }

  statement {
    sid    = "AllowCloudformationReadOperationsOnElasticBeanstalkStacks"
    effect = "Allow"
    actions = [
      "cloudformation:DescribeStackResource",
      "cloudformation:DescribeStackResources",
      "cloudformation:DescribeStacks"
    ]
    resources = [
      "arn:aws:cloudformation:*:*:stack/eb-*",
      "arn:aws:cloudformation:*:*:stack/awseb-*",
    ]
  }

  statement {
    sid       = "AllowDeleteApplicationVersionLifecycle"
    effect    = "Allow"
    actions   = ["elasticbeanstalk:DeleteApplicationVersion"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "elasticbeanstalk:InApplication"
      values   = [aws_elastic_beanstalk_application.sellix-eb.arn]
    }
  }

  /*
  statement { // only if codepipeline is enabled
    sid = "AllowLifecycleS3SourceBundleDeletion"
    effect = "Allow"
    actions = ["s3:DeleteObject", "s3:GetBucketLocation"]
    resources = ["${aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.arn}/*", aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.arn]
  }

  /* needed for lifecycle, versions and manifest management,
     but actually we are using codepipeline's bucket to store the artifacts
     and codepipeline's deploy role to deploy and store applications.
  */

  /*
  statement {
    sid    = "EBDefaultS3BucketPerms"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:ListBucket",
      "s3:PutBucketPolicy"
    ]
    resources = ["arn:aws:s3:::elasticbeanstalk-${local.aws_region}-${local.aws_account_id}"]
  }

  statement {
    sid    = "EBDefaultS3BucketObjectsPerms"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectVersionAcl"
    ]
    resources = ["arn:aws:s3:::elasticbeanstalk-${local.aws_region}-${local.aws_account_id}/*"]
  }
  */

  statement {
    sid = "AllowPassRole"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.sellix-eb-ec2-role.arn
    ]
    effect = "Allow"
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"] // https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/iam-servicerole.html
    }
  }
}

data "aws_iam_policy_document" "sellix-eb-default-policy-document" {
  statement { // needed for instance logs retrieval
    sid = "DefaultS3BucketWriteLogs"
    actions = [
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::elasticbeanstalk-${local.aws_region}-${local.aws_account_id}/resources/environments/logs/*"
    ]
  }

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
      for _, env_name in keys(var.environments) :
      "arn:aws:logs:*:*:log-group:/aws/elasticbeanstalk/${var.tags["Project"]}-${env_name}/var/log/*"
    ]
  }

  statement {
    sid = "XRayAccess"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid       = "ECRAuthToken"
    actions   = ["ecr:GetAuthorizationToken"]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "ECRReadAccess"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    effect    = "Allow"
    resources = [for _, v in aws_ecr_repository.sellix-ecr : v.arn]
  }

  statement {
    sid = ""
    actions = [
      "ec2:AssignIpv6Addresses"
    ]
    effect    = "Allow"
    resources = ["arn:aws:ec2:${local.aws_region}:${local.aws_account_id}:network-interface/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:Vpc"
      values   = ["arn:aws:ec2:${local.aws_region}:${local.aws_account_id}:vpc/${var.vpc_id}"]
    }
  }

  /*
  statement {
    sid = "S3BucketPerms"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions",
    ]
    resources = ["arn:aws:s3:::elasticbeanstalk-${local.aws_region}-${local.aws_account_id}"]
  }
  statement { // found it in S3 bucket permissions
    sid = "S3BucketAccessRead"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::elasticbeanstalk-${local.aws_region}-${local.aws_account_id}/resources/environments/*"
    ]
  }
  */

  statement {
    sid = "ElasticBeanstalkHealthAccess"
    actions = [
      "elasticbeanstalk:PutInstanceStatistics"
    ]
    effect = "Allow"
    resources = [
      for _, env_name in keys(var.environments) :
      "arn:aws:elasticbeanstalk:${local.aws_region}:*:environment/${var.tags["Project"]}/${var.tags["Project"]}-${env_name}"
    ]
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
}

data "aws_iam_policy_document" "sellix-eb-elb-policy-document" {
  count = var.is_production ? 1 : 0

  statement {
    sid = "ELBS3WriteLogs"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      one(aws_s3_bucket.sellix-eb-elb-logs).arn,
      "${one(aws_s3_bucket.sellix-eb-elb-logs).arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [join("", data.aws_elb_service_account.sellix-eb-elb-service[*].arn)]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "sellix-eb-service-policy-sts-document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com"]
    }
    effect = "Allow"
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["elasticbeanstalk"]
    }
  }
}

data "aws_iam_policy_document" "sellix-eb-codepipeline-policy-sts-document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "sellix-eb-codebuild-assumerole-policy-document" {
  // https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up.html
  statement {
    sid    = "AllowCodeBuildAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }
  }
}

data "aws_iam_policy_document" "sellix-eb-service-sns-policy-document" {
  statement {
    sid = "EBHealthNotifications"
    actions = [
      "sns:Publish"
    ]
    resources = [
      for _, env_name in keys(var.environments) :
      "arn:aws:sns:${local.aws_region}:*:ElasticBeanstalkNotifications-Environment-${var.tags["Project"]}-${env_name}"
    ]
    effect = "Allow"
  }
}

// https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up.html
data "aws_iam_policy_document" "sellix-eb-codebuild-policy-document" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectVersion",
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:GetBucketAcl",
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListObjects",
      "s3:ListObjectsV2"
    ]
    resources = [
      aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.arn,
      "${aws_s3_bucket.sellix-eb-codepipeline-s3-bucket.arn}/*",
      "arn:aws:s3:::sellix-assets",
      "arn:aws:s3:::sellix-assets/*"
    ]
  }
}

data "aws_iam_policy_document" "sellix-eb-codebuild-codestar-connection-policy-document" {
  statement {
    sid    = "CodeBuildCodestar"
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection"
    ]
    resources = [var.codestar_connection_arn]
  }
}

data "aws_iam_policy_document" "sellix-eb-codebuild-permissions-policy-document" {
  statement {
    sid       = "ECRToken"
    actions   = ["ecr:GetAuthorizationToken"]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "CBECRPerms"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    effect    = "Allow"
    resources = [for _, v in aws_ecr_repository.sellix-ecr : v.arn]
  }
  statement {
    sid = "CBDefaultPerms"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      /*
      "codecommit:GitPull",
      "ecs:RunTask",
      "iam:PassRole",
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue"
      */
    ]
    effect = "Allow"
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "sellix-eb-codepipeline-s3-permissions-policy-document" {
  statement {
    sid = "CodePipelineBucketPerms"
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

data "aws_iam_policy_document" "sellix-eb-kms-key-policy-document" {
  // see https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up.html#setting-up-kms
  statement {
    sid = "KeyAllow"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.sellix-eb-kms-key.arn]
  }
}

data "aws_iam_policy_document" "sellix-eb-codepipeline-codebuild-permissions-policy-document" {
  statement {
    sid = "CodepipelineOnCodebuildPerms"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    effect    = "Allow"
    resources = [for _, v in aws_codebuild_project.sellix-eb : v.arn]
  }
}

data "aws_iam_policy_document" "sellix-eb-codepipeline-codestar-permissions-policy-document" {
  statement {
    sid = "CodePipelineCodestar"
    actions = [
      "codestar-connections:UseConnection"
    ]
    effect = "Allow"
    resources = [
      var.codestar_connection_arn
    ]
  }
}

data "aws_iam_policy_document" "sellix-eb-codepipeline-codebuild-buildsecrets-policy-document" {
  count = length(var.build_secrets) > 0 ? 1 : 0

  statement {
    effect = "Allow"
    sid    = "CodeBuildRetrieveBuildSecret"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [for _, v in var.build_secrets : v.arn]
  }
}

data "aws_elb_service_account" "sellix-eb-elb-service" {}

resource "aws_iam_role" "sellix-eb-codepipeline-role" {
  name               = "${var.tags["Project"]}-${local.aws_region}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-eb-codepipeline-policy-sts-document.json
}

resource "aws_iam_role" "sellix-eb-service-role" {
  name               = "${var.tags["Project"]}-${local.aws_region}-service-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-eb-service-policy-sts-document.json
}

resource "aws_iam_role" "sellix-eb-ec2-role" {
  name               = "${var.tags["Project"]}-${local.aws_region}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-eb-ec2-policy-document.json
}

resource "aws_iam_instance_profile" "sellix-eb-ec2-instance-profile" {
  name = "${var.tags["Project"]}-${local.aws_region}-ec2-instance-profile"
  role = aws_iam_role.sellix-eb-ec2-role.name
}

resource "aws_iam_role_policy" "sellix-eb-service-sns-policy" {
  name   = "${var.tags["Project"]}-${local.aws_region}-service-sns-policy"
  role   = aws_iam_role.sellix-eb-service-role.id
  policy = data.aws_iam_policy_document.sellix-eb-service-sns-policy-document.json
}

resource "aws_iam_role_policy" "sellix-eb-service-policy" {
  name   = "${var.tags["Project"]}-${local.aws_region}-service-policy"
  role   = aws_iam_role.sellix-eb-service-role.id
  policy = data.aws_iam_policy_document.sellix-eb-service-req-policy-document.json
}

resource "aws_iam_role_policy" "sellix-eb-default-policy" {
  name   = "${var.tags["Project"]}-${local.aws_region}-default-policy"
  role   = aws_iam_role.sellix-eb-ec2-role.id
  policy = data.aws_iam_policy_document.sellix-eb-default-policy-document.json
}

resource "aws_iam_role" "sellix-eb-codebuild-role" {
  name               = "${var.tags["Project"]}-${local.aws_region}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.sellix-eb-codebuild-assumerole-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codebuild-permissions-policy" {
  name        = "${var.tags["Project"]}-${local.aws_region}-codebuild-permissions-policy"
  description = "CodeBuild Service Role"
  policy      = data.aws_iam_policy_document.sellix-eb-codebuild-permissions-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codebuild-policy" {
  name        = "${var.tags["Project"]}-${local.aws_region}-codebuild-policy"
  description = "CodeBuild access policy"
  policy      = data.aws_iam_policy_document.sellix-eb-codebuild-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codebuild-codestar-connection-policy" {
  name        = "${var.tags["Project"]}-${local.aws_region}-codebuild-codestar-connection-policy"
  description = "CodeBuild CodeStar Connection policy"
  policy      = data.aws_iam_policy_document.sellix-eb-codebuild-codestar-connection-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codepipeline-s3-permissions-policy" {
  name   = "${var.tags["Project"]}-${local.aws_region}-codepipeline-s3-permissions-policy"
  policy = data.aws_iam_policy_document.sellix-eb-codepipeline-s3-permissions-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codepipeline-codebuild-permissions-policy" {
  name   = "${var.tags["Project"]}-${local.aws_region}-codepipeline-codebuild-permissions-policy"
  policy = data.aws_iam_policy_document.sellix-eb-codepipeline-codebuild-permissions-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codepipeline-codestar-permissions-policy" {
  name   = "${var.tags["Project"]}-${local.aws_region}-codepipeline-codestar-permissions-policy"
  policy = data.aws_iam_policy_document.sellix-eb-codepipeline-codestar-permissions-policy-document.json
}

resource "aws_iam_policy" "sellix-eb-codepipeline-codebuild-buildsecrets-policy" {
  count = length(data.aws_iam_policy_document.sellix-eb-codepipeline-codebuild-buildsecrets-policy-document)

  name   = "${var.tags["Project"]}-${local.aws_region}-codepipeline-codebuild-buildsecrets-policy"
  policy = one(data.aws_iam_policy_document.sellix-eb-codepipeline-codebuild-buildsecrets-policy-document).json
}

resource "aws_iam_policy" "sellix-eb-kms-key-policy" {
  name        = "${var.tags["Project"]}-${local.aws_region}-kms-key-policy"
  description = "KMS Key Policy"
  policy      = data.aws_iam_policy_document.sellix-eb-kms-key-policy-document.json
}

resource "aws_iam_role_policy_attachment" "sellix-eb-codepipeline-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
  role       = aws_iam_role.sellix-eb-codepipeline-role.id
}

/*
resource "aws_iam_role_policy_attachment" "sellix-eb-enhanced-health-policy-attachment" {
  role       = aws_iam_role.sellix-eb-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "sellix-eb-service-policy-attachment" {
  role       = aws_iam_role.sellix-eb-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}
*/

/*
resource "aws_iam_role_policy_attachment" "sellix-eb-web-tier-policy-attachment" {
  role       = aws_iam_role.sellix-eb-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}
*/

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

resource "aws_iam_role_policy_attachment" "sellix-eb-codebuild-kms-key-policy-attachment" {
  role       = aws_iam_role.sellix-eb-codebuild-role.name
  policy_arn = aws_iam_policy.sellix-eb-kms-key-policy.arn
}

resource "aws_iam_role_policy_attachment" "sellix-eb-codepipeline-kms-key-policy-attachment" {
  role       = aws_iam_role.sellix-eb-codepipeline-role.name
  policy_arn = aws_iam_policy.sellix-eb-kms-key-policy.arn
}

resource "aws_iam_role_policy_attachment" "sellix-eb-codepipeline-codebuild-buildsecrets-policy-attachment" {
  count = length(aws_iam_policy.sellix-eb-codepipeline-codebuild-buildsecrets-policy)

  role       = aws_iam_role.sellix-eb-codebuild-role.name
  policy_arn = one(aws_iam_policy.sellix-eb-codepipeline-codebuild-buildsecrets-policy).arn
}
