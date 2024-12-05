data "aws_arn" "eb-eu-alb-arns-decode" {
  provider = aws.eu-west-1
  for_each = local.is_production ? module.eb-eu-west-1.eb_load_balancers : {}
  arn      = one(each.value)
}

data "aws_arn" "eb-us-alb-arns-decode" {
  provider = aws.us-east-1
  for_each = local.is_production && length(local.multi_region_environments) > 0 ? one(module.eb-us-east-1).eb_load_balancers : {}
  arn      = one(each.value)
}

locals {
  widgets = {
    cw_max_panel_width = 24
    height             = 6
    max_regions_per_x  = length(local.multi_region_environments) > 0 ? 2 : 1 // edit the true one for having more regions on the same line
  }
}

# https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html
# todo: https://emilenijssen.nl/8-aws-elastic-beanstalk-cloudwatch-ram-and-disk-monitoring/
resource "aws_cloudwatch_dashboard" "main" { // use better data structure to be future-proof
  provider       = aws.eu-west-1
  for_each       = local.is_production ? local.environments : {}
  dashboard_name = "${local.tags["Project"]}-${each.key}-dashboard"
  dashboard_body = jsonencode(
    {
      "widgets" : flatten(
        [
          for filename in setunion(
            fileset("${path.module}", "widgets/*.alb.tftpl"),
            fileset("${path.module}", "widgets/*.redis.tftpl"),
            fileset("${path.module}", "widgets/*.ec2.tftpl"),
          ) :
          jsondecode(templatefile(filename, merge({
            albs = merge({
              eu-west-1 = trimprefix(data.aws_arn.eb-eu-alb-arns-decode[each.key].resource, "loadbalancer/"),
              },
              can(data.aws_arn.eb-us-alb-arns-decode[each.key]) ? {
                us-east-1 = trimprefix(data.aws_arn.eb-us-alb-arns-decode[each.key].resource, "loadbalancer/")
            } : {}),
            },
            {
              redis = (local.is_redis && lookup(each.value, "redis", false)) ? merge({
                eu-west-1 = can(one(module.redis-eu-west-1)) ? one(module.redis-eu-west-1).member_clusters : [],
                },
                can(one(module.redis-us-east-1)) ? {
                  us-east-1 = one(module.redis-us-east-1).member_clusters,
              } : {}) : {},
            },
            {
              autoscaling = merge({
                eu-west-1 = module.eb-eu-west-1.autoscaling[each.key]
                },
                can(one(module.eb-us-east-1).autoscaling[each.key]) ? {
                  us-east-1 = one(module.eb-us-east-1).autoscaling[each.key]
              } : {})
            },
            {
              env_name = "${local.tags["Project"]}-${each.key}", // Beanstalk Environment Names
            },
          local.widgets)))
        ]
      )
    }
  )
}