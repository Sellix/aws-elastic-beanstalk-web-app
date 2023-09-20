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

# https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html
# add redis
resource "aws_cloudwatch_dashboard" "main" { // use better data structure to be future-proof
  provider       = aws.eu-west-1
  for_each       = local.is_production ? local.environments : {}
  dashboard_name = "${local.tags["Project"]}-${each.key}-dashboard"
  dashboard_body = templatefile("./cw_dashboard.tftpl", {
    cw_max_panel_width = 24
    env_name = "${local.tags["Project"]}-${each.key}", // Beanstalk Environment Names
    albs = merge({
      eu-west-1 = trimprefix(data.aws_arn.eb-eu-alb-arns-decode[each.key].resource, "loadbalancer/"),
      },
      (length(local.multi_region_environments) > 0 && can(local.multi_region_environments[each.key])) ? {
        us-east-1 = trimprefix(data.aws_arn.eb-us-alb-arns-decode[each.key].resource, "loadbalancer/")
    } : {}),
    max_regions_per_x = length(local.multi_region_environments) > 0 ? 2 : 1 // edit the true one for having more regions on the same line
    height            = 6
  })
}