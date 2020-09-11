resource "aws_elastic_beanstalk_environment" "sellix-web-app" {
  name                   = "sellix-web-app-prod"
  application            = "sellix-web-app"
  tier                   = "WebServer"
  wait_for_ready_timeout = "20m"
  solution_stack_name    = "64bit Amazon Linux 2 v5.2.1 running Node.js 12"
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
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
    value     = aws_key_pair.sellix-web-app-keypair.key_name
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.sellix-web-app-vpc.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.sellix-web-app-subnet.id
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
    value     = "5"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2.name
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.service.name
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.sellix-web-app-security-group.id
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

resource "aws_elastic_beanstalk_application" "sellix-web-app" {
  name        = "sellix-web-app"
  description = "Frontend NODE.JS Web Application"
}

resource "aws_elastic_beanstalk_application_version" "sellix-web-app" {
  name        = "sellix-web-app"
  application = aws_elastic_beanstalk_application.sellix-web-app.name
  description = "application version created by terraform"
  bucket      = "sellix-elastic-beanstalk-hello-world"
  key         = "hello-world.zip"
}