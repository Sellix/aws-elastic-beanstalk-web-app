resource "aws_secretsmanager_secret" "build-secrets" {
  provider = aws.eu-west-1
  for_each = {
    for k, v in local.environments :
    k => v
    if tobool(lookup(v, "has_secret", false))
  }
  name        = "${local.tags["Project"]}-${each.key}-build"
  description = "${each.key} (code)build secret"

  dynamic "replica" {
    for_each = can(local.multi_region_environments[each.key]) ? range(1) : []

    content {
      region = "us-east-1"
    }
  }

  tags = local.tags
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }
}

locals {
  build_secrets = { for k, v in aws_secretsmanager_secret.build-secrets : k => v.name }
}
