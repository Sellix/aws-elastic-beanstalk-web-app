module "elb-alarms-eu-west-1" {
  for_each = local.is_production ? module.eb-eu-west-1.eb_load_balancers : {}
  source   = "./elb-alarms"
  providers = {
    aws = aws.eu-west-1
  }

  name    = each.key
  elb_arn = one(each.value)
  tags    = local.tags
}

module "elb-alarms-us-east-1" {
  for_each = length(module.eb-us-east-1) > 0 && local.is_production ? one(module.eb-us-east-1).eb_load_balancers : {}
  source   = "./elb-alarms"
  providers = {
    aws = aws.us-east-1
  }

  name    = each.key
  elb_arn = one(each.value)
  tags    = local.tags
}
