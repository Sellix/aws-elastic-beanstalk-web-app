locals {
  env = {
    ELASTIC_BEANSTALK_PORT = 8080
    DOMAIN                 = local.production ? "sellix.io" : "sellix.gg"
    ENVIRONMENT            = local.production ? "production" : "staging"
  }
  production             = contains(["prod"], substr(terraform.workspace, 0, 4)) ? true : false
  notification_topic_arn = {for s in aws_elastic_beanstalk_environment.sellix-web-app-environment.all_settings :
    s.name => s.value if s.namespace == "aws:elasticbeanstalk:sns:topics" && s.name == "Notification Topic ARN"}
  availability_zones     = ["${var.aws_region}a", "${var.aws_region}b"]
  traffic_splitting      = local.production ? [
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
      value     = local.production ? var.ssl_production_acm_arn : var.ssl_staging_acm_arn
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
      value     = local.production ? "m5.large" : "t3.micro"
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "RootVolumeType"
      value     = "gp2"
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "RootVolumeSize"
      value     = local.production ? "50" : "10"
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
      name      = "MinSize"
      value     = "1"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "MaxSize"
      value     = local.production ? "15" : "5"
    },
    {
      namespace = "aws:autoscaling:updatepolicy:rollingupdate"
      name      = "RollingUpdateType"
      value     = local.production ? "Health" : "Immutable"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "MeasureName"
      value     = "CPUUtilization"
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
      name      = "BreachDuration"
      value     = "1"
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "Period"
      value     = "1"
    }
  ]
}