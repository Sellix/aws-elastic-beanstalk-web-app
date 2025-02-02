data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  aws_region     = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id

  docker_environments = [
    for k, v in var.environments : k
    if lower(lookup(v, "stack_name", "")) == "docker"
  ]

  codebuild_envs = {
    for k, v in var.environments : k =>
    can(v.versions.codebuild) ?
    v.versions.codebuild : var.default_codebuild_image
  }

  env = { for env_name, vals in var.environments : env_name => merge({
    ELASTIC_BEANSTALK_PORT = 8080
    ENVIRONMENT            = var.is_production ? "production" : "staging"
    },
    contains(local.docker_environments, env_name) ? {
      AWS_REGION     = local.aws_region
      AWS_ACCOUNT_ID = local.aws_account_id
    } : {},
    (tobool(vals.redis) && length(var.redis_endpoint) > 0) ? {
      REDIS_HOST     = var.redis_endpoint
      REDIS_PORT     = 6379
      REDIS_URL      = "redis://${var.redis_endpoint}:6379"
      REDIS_URL_READ = "redis://${var.redis_read_endpoint}:6379"
    } : {})
  }

  ssl_arn = lookup(var.ssl_arn[local.aws_region], tostring(var.is_production), "")
  is_ssl  = length(local.ssl_arn) > 0

  // todo: split listeners and processes
  eb_processes = merge(local.is_ssl ?
    {
      "https" : {
        "protocol" : var.ssl_listener ? "https" : "http",
        "port" : "443",
        "is_ssl" : true,
      }
    } : {},
    {
      "default" : {
        "protocol" : "http",
        "port" : "80",
        "is_ssl" : false,
      }
  })


  /*  notification_topic_arn = { for s in aws_elastic_beanstalk_environment.sellix-eb-environment.all_settings :
  s.name => s.value if s.namespace == "aws:elasticbeanstalk:sns:topics" && s.name == "Notification Topic ARN" }*/
  vpc = { for k, v in var.environments : k => [
    {
      namespace = "aws:ec2:vpc"
      name      = "VPCId"
      value     = var.vpc_id
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "ELBScheme"
      value     = !(var.is_production && tobool(lookup(v, "global_accelerator", false))) ? "public" : "internal" // elb sg, edit it to have [public]-facing alb
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "Subnets"
      value     = var.is_production ? join(",", sort(var.vpc_subnets["private"][*])) : join(",", sort(var.vpc_subnets["public"][*])) // var.is_production ? join(",", sort(aws_subnet.sellix-eb-private-subnet[*].id)) : aws_subnet.sellix-eb-private-subnet[0].id
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "AssociatePublicIpAddress"
      value     = tostring(!var.is_production)
    }
    ]
  }

  environment = concat(var.is_production ? concat([
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
    ],
    flatten([for process, options in local.eb_processes : [{
      namespace = "aws:elasticbeanstalk:environment:process:${process}"
      name      = "DeregistrationDelay"
      value     = "20"
      },
      {
        namespace = "aws:elasticbeanstalk:environment:process:${process}"
        name      = "HealthyThresholdCount"
        value     = "3"
      },
      {
        namespace = "aws:elasticbeanstalk:environment:process:${process}"
        name      = "Port"
        value     = options.port
      },
      {
        namespace = "aws:elasticbeanstalk:environment:process:${process}"
        name      = "Protocol"
        value     = upper(options.protocol)
      },
      {
        namespace = "aws:elasticbeanstalk:environment:process:${process}"
        name      = "StickinessEnabled"
        value     = "true"
      },
      {
        namespace = "aws:elasticbeanstalk:environment:process:${process}"
        name      = "StickinessLBCookieDuration"
        value     = "86400"
      },
      {
        namespace = "aws:elasticbeanstalk:environment:process:${process}"
        name      = "StickinessType"
        value     = "lb_cookie"
    }]])
    ) : [
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "EnvironmentType"
      value     = "SingleInstance"
    }
    ], [
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "ServiceRole"
      value     = aws_iam_role.sellix-eb-service-role.arn
    }
  ])

  cloudwatch = concat([
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs"
      name      = "StreamLogs"
      value     = tostring(var.cloudwatch_logs_days["instance"] != null)
    },
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
      name      = "HealthStreamingEnabled"
      value     = tostring(var.cloudwatch_logs_days["healthd"] != null)
    },
    ], var.cloudwatch_logs_days["instance"] != null ? [
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs"
      name      = "RetentionInDays"
      value     = var.cloudwatch_logs_days["instance"]
    },
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs"
      name      = "DeleteOnTerminate"
      value     = "false"
    },
    ] : [],
    var.cloudwatch_logs_days["healthd"] != null ? [
      {
        namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
        name      = "RetentionInDays"
        value     = var.cloudwatch_logs_days["healthd"]
      },
      {
        namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
        name      = "DeleteOnTerminate"
        value     = "false"
      },
    ] : []
  )

  per_app_healthcheck = {
    for k, v in var.environments : k => flatten(
      [
        for process, options in local.eb_processes : [
          {
            namespace = "aws:elasticbeanstalk:environment:process:${process}"
            name      = "HealthCheckPath"
            value     = can(v.healthcheck) ? v.healthcheck : "/"
          }
        ]
      ]
    )
  }

  healthcheck = concat([
    {
      namespace = "aws:elasticbeanstalk:command"
      name      = "IgnoreHealthCheck"
      value     = "false"
    },
    ],
    flatten([for process, options in local.eb_processes : var.is_production ? [
      {
        namespace = "aws:elasticbeanstalk:environment:process:${process}"
        name      = "HealthCheckInterval"
        value     = "15"
      },
      {
        namespace = "aws:elasticbeanstalk:environment:process:${process}"
        name      = "HealthCheckTimeout"
        value     = "5"
      },
      {
        namespace = "aws:elasticbeanstalk:environment:process:${process}"
        name      = "UnhealthyThresholdCount"
        value     = "5"
      },
    ] : []])
  )
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

  generic_elb = { for k, v in var.environments : k => [
    {
      namespace = "aws:ec2:vpc"
      name      = "ELBSubnets"
      value     = var.is_production && tobool(lookup(v, "global_accelerator", false)) ? join(",", sort(var.vpc_subnets["private"][*])) : join(",", sort(var.vpc_subnets["public"][*]))
    }
    ]
  }

  alb_listeners = flatten([
    for process, options in local.eb_processes :
    concat(
      [
        {
          namespace = "aws:elbv2:listener:${options.port}"
          name      = "DefaultProcess"
          value     = process
        },
        {
          namespace = "aws:elbv2:listener:${options.port}"
          name      = "ListenerEnabled"
          value     = true
        },
        {
          namespace = "aws:elbv2:listener:${options.port}"
          name      = "Protocol"
          value     = upper(options.protocol)
        },
      ],
      options.protocol == "https" || options.is_ssl ? [
        {
          namespace = "aws:elbv2:listener:${options.port}"
          name      = "SSLCertificateArns"
          value     = local.ssl_arn
        },
        {
          namespace = "aws:elbv2:listener:${options.port}"
          name      = "SSLPolicy"
          # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html
          value = "ELBSecurityPolicy-TLS13-1-2-2021-06"
        }
      ] : []
  )])

  alb_logs = {
    for name, _ in var.environments :
    name => var.is_production ? [{
      namespace = "aws:elbv2:loadbalancer"
      name      = "AccessLogsS3Prefix"
      value     = "${name}"
    }] : []
  }

  alb = var.is_production ? concat([
    {
      namespace = "aws:elbv2:loadbalancer"
      name      = "ManagedSecurityGroup" // SecurityGroups
      value     = aws_security_group.sellix-eb-elb-security-group.id
    },
    {
      namespace = "aws:elbv2:loadbalancer"
      name      = "SecurityGroups"
      value     = aws_security_group.sellix-eb-elb-security-group.id
    },
    {
      namespace = "aws:elbv2:loadbalancer"
      name      = "AccessLogsS3Bucket"
      value     = one(aws_s3_bucket.sellix-eb-elb-logs).id
    },
    {
      namespace = "aws:elbv2:loadbalancer"
      name      = "AccessLogsS3Enabled"
      value     = "true"
    }
  ], local.alb_listeners) : []

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
      value = join(",",
        [aws_security_group.sellix-eb-security-group.id],
      !var.is_production ? [aws_security_group.sellix-eb-elb-security-group.id] : [])
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "SSHSourceRestriction"
      value     = "tcp,22,22,127.0.0.1/32"
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "RootVolumeType"
      value     = "gp2"
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "RootVolumeSize"
      value     = var.is_production ? "25" : "10"
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

  autoscaling_vars = {
    for name, opts in var.environments :
    name =>
    concat(
      var.is_production ? [
        {
          namespace = "aws:autoscaling:asg"
          name      = "MaxSize"
          value     = can(opts.asg) ? lookup(opts.asg, "maxsize", "1") : "1"
        },
        {
          namespace = "aws:autoscaling:asg"
          name      = "MinSize"
          value     = can(opts.asg) ? lookup(opts.asg, "minsize", "1") : "1"
        },
      ] : []
    )
  }

  default_autoscaling_triggers = {
    MeasureName               = "CPUUtilization"
    Statistic                 = "Average"
    Unit                      = "Percent"
    LowerThreshold            = "20"
    UpperThreshold            = "70"
    LowerBreachScaleIncrement = "-1"
    UpperBreachScaleIncrement = "1"
    BreachDuration            = "1"
    Period                    = "1"
    EvaluationPeriods         = "1"
  }

  autoscaling_triggers = {
    for name, opts in var.environments :
    name =>
    var.is_production ? [for k, v in local.default_autoscaling_triggers :
      {
        namespace = "aws:autoscaling:trigger"
        name      = k
        value     = can(opts.asg_triggers) ? lookup(opts.asg_triggers, k, v) : v
      }
    ] : []
  }

  autoscaling = concat(
    [
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
        namespace = "aws:autoscaling:updatepolicy:rollingupdate"
        name      = "RollingUpdateType"
        value     = "Immutable"
      },
      {
        namespace = "aws:autoscaling:updatepolicy:rollingupdate"
        name      = "Timeout"
        value     = "PT30M"
    }]
  )
}
