data "aws_elastic_beanstalk_solution_stack" "nodejs" {
  for_each    = toset(keys(var.environments))
  most_recent = true

  name_regex = "^64bit Amazon Linux (.*) running Node.js ${var.environments[each.value]["versions"]["nodejs"]}$"
}

resource "aws_elastic_beanstalk_environment" "sellix-eb-environment" {
  for_each               = local.envs_map
  name                   = "${var.tags["Project"]}-${each.value}"
  application            = aws_elastic_beanstalk_application.sellix-eb.name
  tier                   = "WebServer"
  wait_for_ready_timeout = "20m"
  solution_stack_name    = data.aws_elastic_beanstalk_solution_stack.nodejs[each.value].name
  setting {
    namespace = "aws:elasticbeanstalk:monitoring"
    name      = "Automatically Terminate Unhealthy Instances"
    value     = "true"
    resource  = ""
  }
  setting {
    namespace = "aws:ec2:instances"
    name      = "SupportedArchitectures"
    value     = "arm64"
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
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = each.value == "shop-app" ? "/.well-known/health" : "/"
    resource  = ""
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.is_production ? "m6g.large" : "m6g.medium"
  }

  # environment
  dynamic "setting" {
    for_each = merge(local.env, var.environments[each.value]["vars"])
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
      resource  = ""
    }
  }

  dynamic "setting" {
    for_each = concat(
      local.vpc,
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
  lifecycle {
    ignore_changes = [setting]
  }
  tags = var.tags
}

resource "aws_elastic_beanstalk_application" "sellix-eb" {
  name        = var.tags["Project"]
  description = "NodeJS Web Application"
}
