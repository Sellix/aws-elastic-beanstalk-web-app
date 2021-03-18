resource "aws_elastic_beanstalk_environment" "sellix-web-app-environment" {
  name                   = "sellix-web-app-${terraform.workspace}"
  application            = aws_elastic_beanstalk_application.sellix-web-app.name
  tier                   = "WebServer"
  wait_for_ready_timeout = "20m"
  solution_stack_name    = "64bit Amazon Linux 2 v5.3.0 running Node.js 14"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.sellix-web-app-vpc.id
    resource  = ""
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", sort(aws_subnet.sellix-web-app-private-subnet.*.id))
    resource  = ""
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "false"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.sellix-web-app-service-role.name
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "90"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
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
  # traffic splitting
  dynamic "setting" {
    for_each = local.traffic_splitting
    content {
      namespace = setting.value["namespace"]
      name      = setting.value["name"]
      value     = setting.value["value"]
      resource  = ""
    }
  }
  # alb
  dynamic "setting" {
    for_each = concat(local.generic_elb, local.alb)
    content {
      namespace = setting.value["namespace"]
      name      = setting.value["name"]
      value     = setting.value["value"]
      resource  = ""
    }
  }
  # autoscaling
  dynamic "setting" {
    for_each = concat(local.autoscaling_launch_config, local.autoscaling)
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