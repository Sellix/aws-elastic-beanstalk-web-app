data "aws_region" "current" {}

locals {
  aws_region     = data.aws_region.current.name
  codebuild_envs = distinct([for k in keys(var.environments) : var.environments[k]["versions"]["codebuild"]])
  envs_map       = { for i, env in keys(var.environments) : tonumber(i) => env }
  env = { for _, env_name in local.envs_map : env_name => {
    ELASTIC_BEANSTALK_PORT = 8080
    DOMAIN                 = "${var.environments[env_name]["domain"]}.${var.is_production ? "io" : "gg"}"
    ENVIRONMENT            = var.is_production ? "production" : "staging"
    NODE_ENV               = "prod"
    REDIS_HOST             = var.redis_endpoint
    REDIS_PORT             = 6379
    REDIS_URL              = "redis://${var.redis_endpoint}:6379"
    REDIS_URL_READ         = "redis://${var.redis_read_endpoint}:6379"
  } }

  /*  notification_topic_arn = { for s in aws_elastic_beanstalk_environment.sellix-eb-environment.all_settings :
  s.name => s.value if s.namespace == "aws:elasticbeanstalk:sns:topics" && s.name == "Notification Topic ARN" }*/
  vpc = [
    {
      namespace = "aws:ec2:vpc"
      name      = "VPCId"
      value     = var.vpc_id
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "ELBScheme"
      value     = "public"
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "Subnets"
      value     = join(",", sort(var.vpc_subnets["private"][*].id)) // var.is_production ? join(",", sort(aws_subnet.sellix-eb-private-subnet[*].id)) : aws_subnet.sellix-eb-private-subnet[0].id
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "AssociatePublicIpAddress"
      value     = "false"
    }
  ]
  environment = [
    {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name      = "DeregistrationDelay"
      value     = "20"
    },
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "EnvironmentType"
      value     = "LoadBalanced"
    },
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "LoadBalancerType"
      value     = "application"
    },
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "ServiceRole"
      value     = aws_iam_role.sellix-eb-service-role.arn
    },
    {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name      = "HealthyThresholdCount"
      value     = "3"
    },
    {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name      = "Port"
      value     = "80"
    },
    {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name      = "Protocol"
      value     = "HTTP"
    },
    {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name      = "UnhealthyThresholdCount"
      value     = "5"
    },
    {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name      = "StickinessEnabled"
      value     = "true"
    },
    {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name      = "StickinessLBCookieDuration"
      value     = "86400"
    },
    {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name      = "StickinessType"
      value     = "lb_cookie"
    }
  ]
  cloudwatch = [
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs"
      name      = "DeleteOnTerminate"
      value     = "false"
    },
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs"
      name      = "RetentionInDays"
      value     = "90"
    },
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs"
      name      = "StreamLogs"
      value     = "true"
    },
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
      name      = "DeleteOnTerminate"
      value     = "false"
    },
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
      name      = "HealthStreamingEnabled"
      value     = "false"
    },
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
      name      = "RetentionInDays"
      value     = "7"
    },
  ]
  healthcheck = [
    {
      namespace = "aws:elasticbeanstalk:command"
      name      = "IgnoreHealthCheck"
      value     = "false"
    },
    {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name      = "HealthCheckInterval"
      value     = "15"
    },
    {
      namespace = "aws:elasticbeanstalk:environment:process:default"
      name      = "HealthCheckTimeout"
      value     = "5"
    },
  ]
  command = [
    {
      namespace = "aws:elasticbeanstalk:command"
      name      = "BatchSize"
      value     = "100"
    },
    {
      namespace = "aws:elasticbeanstalk:command"
      name      = "BatchSizeType"
      value     = "Percentage"
    },
    {
      namespace = "aws:elasticbeanstalk:command"
      name      = "Timeout"
      value     = "600"
    },
  ]
  traffic_splitting = var.canary_deployments ? [
    {
      namespace = "aws:elasticbeanstalk:trafficsplitting"
      name      = "EvaluationTime"
      value     = "5"
    },
    {
      namespace = "aws:elasticbeanstalk:trafficsplitting"
      name      = "NewVersionPercent"
      value     = "10"
    },
    {
      namespace = "aws:elasticbeanstalk:command"
      name      = "DeploymentPolicy"
      value     = "TrafficSplitting"
    }
    ] : [
    {
      namespace = "aws:elasticbeanstalk:command"
      name      = "DeploymentPolicy"
      value     = var.is_production ? "Immutable" : "AllAtOnce"
    }
  ]
  generic_elb = [
    {
      namespace = "aws:ec2:vpc"
      name      = "ELBSubnets"
      value     = join(",", sort(var.vpc_subnets["public"][*].id))
    }
  ]
  alb = [
    {
      namespace = "aws:elbv2:loadbalancer"
      name      = "SecurityGroups"
      value     = var.sgr["elb"].id
    },
    {
      namespace = "aws:elbv2:listener:443"
      name      = "ListenerEnabled"
      value     = tostring(length(lookup(var.ssl_arn[local.aws_region], terraform.workspace, "")) > 0)
    },
    {
      namespace = "aws:elbv2:listener:443"
      name      = "Protocol"
      value     = "HTTPS"
    },
    {
      namespace = "aws:elbv2:listener:443"
      name      = "SSLCertificateArns"
      value     = lookup(var.ssl_arn[local.aws_region], terraform.workspace, "false")
    },
    {
      namespace = "aws:elbv2:loadbalancer"
      name      = "AccessLogsS3Bucket"
      value     = aws_s3_bucket.sellix-eb-elb-logs.id
    },
    {
      namespace = "aws:elbv2:loadbalancer"
      name      = "AccessLogsS3Enabled"
      value     = "true"
    }
  ]
  autoscaling_launch_config = [
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "DisableIMDSv1",
      value     = true
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.sellix-eb-ec2-instance-profile.name
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "SecurityGroups"
      value     = var.sgr["eb"].id
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "SSHSourceRestriction"
      value     = "tcp, 22, 22, 127.0.0.1/32"
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "RootVolumeType"
      value     = "gp2"
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "RootVolumeSize"
      value     = var.is_production ? "50" : "10"
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "EC2KeyName"
      value     = aws_key_pair.sellix-eb-keypair.key_name
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "MonitoringInterval"
      value     = "1 minute"
    }
  ]
  autoscaling = [
    {
      namespace = "aws:autoscaling:asg"
      name      = "Cooldown"
      value     = "60"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "EnableCapacityRebalancing"
      value     = "false"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "MinSize"
      value     = var.is_production ? "2" : "1"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "MaxSize"
      value     = var.is_production ? "8" : "2"
    },
    {
      namespace = "aws:autoscaling:updatepolicy:rollingupdate"
      name      = "RollingUpdateType"
      value     = "Immutable"
    },
    {
      namespace = "aws:autoscaling:updatepolicy:rollingupdate"
      name      = "Timeout"
      value     = "PT30M"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "MeasureName"
      value     = "CPUUtilization"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "Statistic"
      value     = "Average"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "Unit"
      value     = "Percent"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "LowerThreshold"
      value     = "20"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "UpperThreshold"
      value     = "70"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "LowerBreachScaleIncrement"
      value     = "-1"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "UpperBreachScaleIncrement"
      value     = "1"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "BreachDuration"
      value     = "1"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "Period"
      value     = "1"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "EvaluationPeriods"
      value     = "1"
    }
  ]
}
