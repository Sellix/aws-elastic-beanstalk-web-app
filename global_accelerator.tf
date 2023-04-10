locals {
  elbs        = [module.eb-eu-west-1[*].eb_load_balancers, module.eb-us-east-1[*].eb_load_balancers]
  elbs_length = length(flatten(local.elbs))
}

resource "aws_globalaccelerator_accelerator" "production-ga" {
  provider        = aws.eu-west-1
  count           = (local.is_production && var.is_global_accelerator) ? length(local.environments) : 0
  name            = "sellix-${keys(local.environments)[count.index]}-ga"
  ip_address_type = "IPV4"
  enabled         = true
  tags            = local.tags
}

resource "aws_globalaccelerator_listener" "production-ga-listener" {
  provider = aws.eu-west-1
  count    = length(aws_globalaccelerator_accelerator.production-ga)
  port_range {
    from_port = 80
    to_port   = 80
  }

  port_range {
    from_port = 443
    to_port   = 443
  }

  protocol        = "TCP"
  accelerator_arn = aws_globalaccelerator_accelerator.production-ga[count.index].id
}

resource "aws_globalaccelerator_endpoint_group" "production-ga-eu-eg" {
  provider     = aws.eu-west-1
  count        = (local.is_production && var.is_global_accelerator) ? length(local.environments) : 0
  listener_arn = aws_globalaccelerator_listener.production-ga-listener[count.index].id
  endpoint_configuration {
    client_ip_preservation_enabled = true
    endpoint_id                    = flatten(local.elbs[0])[keys(local.environments)[count.index]][0]
    weight                         = 100 / local.elbs_length
  }
}

resource "aws_globalaccelerator_endpoint_group" "production-ga-us-eg" {
  provider     = aws.eu-west-1
  count        = (local.is_production && var.is_global_accelerator) ? length(local.environments) : 0
  listener_arn = aws_globalaccelerator_listener.production-ga-listener[count.index].id
  endpoint_configuration {
    client_ip_preservation_enabled = true
    endpoint_id                    = flatten(local.elbs[1])[keys(local.environments)[count.index]][0]
    weight                         = 100 / local.elbs_length
  }
}