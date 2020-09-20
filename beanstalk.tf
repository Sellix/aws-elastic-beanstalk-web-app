resource "aws_elastic_beanstalk_environment" "web-app-environment" {
  name                   = "sellix-web-app-production"
  application            = aws_elastic_beanstalk_application.web-app.name
  tier                   = "WebServer"
  wait_for_ready_timeout = "20m"
  solution_stack_name    = "64bit Amazon Linux 2 v5.2.1 running Node.js 12"
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.medium"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeType"
    value     = "gp2"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = aws_key_pair.web-app-keypair.key_name
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.web-app-vpc.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.web-app-subnet.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "false"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "15"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.web-app-ec2-instance-profile.name
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.web-app-service-role.name
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.web-app-security-group.id
    resource  = ""
  }
  dynamic "setting" {
    for_each = var.env_vars
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
      resource  = ""
    }
  }
}

resource "aws_elastic_beanstalk_application" "web-app" {
  name        = "sellix-web-app"
  description = "NodeJS Web Application"
}

resource "aws_elastic_beanstalk_application_version" "web-app-version" {
  name        = "sellix-web-app-version"
  application = aws_elastic_beanstalk_application.web-app.name
  description = "application version created by terraform"
  bucket      = "sellix-elastic-beanstalk-hello-world"
  key         = "hello-world.zip"
}