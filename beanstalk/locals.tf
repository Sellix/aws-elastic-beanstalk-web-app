data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  tags = {
    "Project"     = "sellix-web-app-v2-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
  env = {
    ELASTIC_BEANSTALK_PORT = 8080
    DOMAIN                 = var.is_production ? "sellix.io" : "sellix.gg"
    ENVIRONMENT            = var.is_production ? "production" : "staging"
  }
  notification_topic_arn = { for s in aws_elastic_beanstalk_environment.sellix-web-app-environment.all_settings :
  s.name => s.value if s.namespace == "aws:elasticbeanstalk:sns:topics" && s.name == "Notification Topic ARN" }
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  vpc = [
    {
      namespace = "aws:ec2:vpc"
      name      = "VPCId"
      value     = aws_vpc.sellix-web-app-vpc.id
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "ELBScheme"
      value     = "public"
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "Subnets"
      value     = var.is_production ? join(",", sort(aws_subnet.sellix-web-app-private-subnet.*.id)) : aws_subnet.sellix-web-app-private-subnet[0].id
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
      value     = aws_iam_role.sellix-web-app-service-role.name
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
      name      = "HealthCheckPath"
      value     = "/"
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
  traffic_splitting = var.is_production ? [
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
      value     = "Immutable"
    }
  ]
  generic_elb = [
    {
      namespace = "aws:ec2:vpc"
      name      = "ELBSubnets"
      value     = join(",", sort(aws_subnet.sellix-web-app-public-subnet.*.id))
    }
  ]
  alb = [
    {
      namespace = "aws:elbv2:loadbalancer"
      name      = "SecurityGroups"
      value     = aws_security_group.sellix-web-app-elb-security-group.id
    },
    {
      namespace = "aws:elbv2:listener:443"
      name      = "ListenerEnabled"
      value     = "true"
    },
    {
      namespace = "aws:elbv2:listener:443"
      name      = "Protocol"
      value     = "HTTPS"
    },
    {
      namespace = "aws:elbv2:listener:443"
      name      = "SSLCertificateArns"
      value     = var.ssl_arn[var.aws_region][terraform.workspace]
    },
    {
      namespace = "aws:elbv2:loadbalancer"
      name      = "AccessLogsS3Bucket"
      value     = aws_s3_bucket.sellix-web-app-elb-logs.id
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
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.sellix-web-app-ec2-instance-profile.name
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "SecurityGroups"
      value     = aws_security_group.sellix-web-app-security-group.id
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "InstanceType"
      value     = var.is_production ? "m5.large" : "t3.micro"
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
      value     = aws_key_pair.sellix-web-app-keypair.key_name
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
      value     = var.is_production ? "10" : "5"
    },
    {
      namespace = "aws:autoscaling:updatepolicy:rollingupdate"
      name      = "RollingUpdateType"
      value     = var.is_production ? "Health" : "Immutable"
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