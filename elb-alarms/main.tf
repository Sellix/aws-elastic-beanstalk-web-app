terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 5.0"
    }
  }
}

variable "elb_arn" {
  type     = string
  nullable = false
}

variable "name" {
  type        = string
  nullable    = false
  description = "resource name"
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "sns_topic_arns" {
  type     = list(string)
  default  = null
  nullable = true
}

data "aws_lb" "elb" {
  arn = var.elb_arn
}

output "test" {
  value = data.aws_lb.elb
}

resource "aws_cloudwatch_metric_alarm" "elb-unhealthyhosts" {
  alarm_name          = "${var.tags["Project"]}-${var.name}-UnHealthyHostCount"
  alarm_description   = "UnHealthyHostCount gte 2"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  period              = 60
  statistic           = "Maximum"
  threshold           = 2
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"

  dimensions = {
    LoadBalancer = data.aws_lb.elb.arn_suffix
  }

  alarm_actions = var.sns_topic_arns
  tags          = var.tags
}

resource "aws_cloudwatch_metric_alarm" "elb-latency" {
  alarm_name          = "${var.tags["Project"]}-${var.name}-TargetResponseTime-1s"
  alarm_description   = "Latency over 1s"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  period              = 60
  statistic           = "Average"
  threshold           = 1
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"

  dimensions = {
    LoadBalancer = data.aws_lb.elb.arn_suffix
  }

  alarm_actions = var.sns_topic_arns
  tags          = var.tags
}

resource "aws_cloudwatch_metric_alarm" "elb-5xx" {
  alarm_name          = "${var.tags["Project"]}-${var.name}-HTTPCode_ELB_5XX"
  alarm_description   = "5XX"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX"

  dimensions = {
    LoadBalancer = data.aws_lb.elb.arn_suffix
  }

  alarm_actions = var.sns_topic_arns
  tags          = var.tags
}
