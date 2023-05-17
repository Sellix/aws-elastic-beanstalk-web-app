locals {
  ga_environments = { for k, v in local.environments : k => v
    if tobool(lookup(v, "global_accelerator", false))
  }
}

resource "aws_globalaccelerator_accelerator" "production-ga" {
  provider        = aws.eu-west-1
  for_each        = local.is_production ? local.ga_environments : {}
  name            = "sellix-${each.key}-ga"
  ip_address_type = "IPV4"
  enabled         = true
  tags            = local.tags
}

resource "aws_globalaccelerator_listener" "production-ga-listener" {
  provider = aws.eu-west-1
  for_each = aws_globalaccelerator_accelerator.production-ga
  port_range {
    from_port = 80
    to_port   = 80
  }

  port_range {
    from_port = 443
    to_port   = 443
  }

  protocol        = "TCP"
  accelerator_arn = each.value.id
}

resource "aws_globalaccelerator_endpoint_group" "production-ga-eu-eg" {
  provider                = aws.eu-west-1
  for_each                = aws_globalaccelerator_accelerator.production-ga
  listener_arn            = aws_globalaccelerator_listener.production-ga-listener[each.key].id
  traffic_dial_percentage = 50
  health_check_path       = local.ga_environments[each.key]["healthcheck"]
  health_check_port       = 80

  dynamic "endpoint_configuration" {
    for_each = module.eb-eu-west-1.eb_load_balancers[each.key]

    content {
      client_ip_preservation_enabled = true
      endpoint_id                    = endpoint_configuration.value
    }
  }

  lifecycle {
    # replace_triggered_by = [module.eb-eu-west-1]
    ignore_changes = [endpoint_configuration, health_check_path]
  }
}

resource "aws_globalaccelerator_endpoint_group" "production-ga-us-eg" {
  provider                = aws.us-east-1
  for_each                = aws_globalaccelerator_accelerator.production-ga
  listener_arn            = aws_globalaccelerator_listener.production-ga-listener[each.key].id
  traffic_dial_percentage = 50
  health_check_path       = local.ga_environments[each.key]["healthcheck"]
  health_check_port       = 80

  dynamic "endpoint_configuration" {
    for_each = one(module.eb-us-east-1).eb_load_balancers[each.key]

    content {
      client_ip_preservation_enabled = true
      endpoint_id                    = endpoint_configuration.value
    }
  }

  lifecycle {
    # replace_triggered_by = [one(module.eb-us-east-1)]
    ignore_changes = [endpoint_configuration, health_check_path]
  }
}