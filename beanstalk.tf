resource "aws_elastic_beanstalk_environment" "sellix-web-app-environment" {
  name                   = "sellix-web-app-${terraform.workspace}"
  application            = aws_elastic_beanstalk_application.sellix-web-app.name
  tier                   = "WebServer"
  wait_for_ready_timeout = "20m"
  solution_stack_name    = "64bit Amazon Linux 2 v5.3.0 running Node.js 14"
  setting {
    namespace = "aws:elasticbeanstalk:monitoring"
    name      = "Automatically Terminate Unhealthy Instances"
    value     = "true"
    resource  = ""
  }
  setting {
    namespace = "aws:ec2:instances"
    name      = "SpotFleetOnDemandAboveBasePercentage"
    value     = "70"
    resource  = ""
  }
  setting {
    namespace = "aws:ec2:instances"
    name      = "SpotFleetOnDemandBase"
    value     = "0"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "EnhancedHealthAuthEnabled"
    value     = "false"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "HealthCheckSuccessThreshold"
    value     = "Ok"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:sns:topics"
    name      = "Notification Endpoint"
    value     = "alarms@sellix.io"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:sns:topics"
    name      = "Notification Protocol"
    value     = "email"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:hostmanager"
    name      = "LogPublicationControl"
    value     = "true"
    resource  = ""
  }

  # environment
  dynamic "setting" {
    for_each = local.env
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
      resource  = ""
    }
  }

  dynamic "setting" {
    for_each = concat(local.vpc,
      local.environment,
      local.cloudwatch,
      local.healthcheck,
      local.command,
      local.traffic_splitting,
      local.generic_elb,
      local.alb,
      local.autoscaling_launch_config,
      local.autoscaling
    )
    content {
      namespace = setting.value["namespace"]
      name      = setting.value["name"]
      value     = setting.value["value"]
      resource  = ""
    }
  }
  tags = {
    "Project" = "sellix-web-app-${terraform.workspace}"
  }
}

resource "aws_elastic_beanstalk_application" "sellix-web-app" {
  name        = "sellix-web-app-${terraform.workspace}"
  description = "NodeJS Web Application"
}