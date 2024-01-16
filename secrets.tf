resource "aws_secretsmanager_secret" "build-secrets" {
  provider    = aws.eu-west-1
  for_each    = { for k, v in local.environments : k => v if tobool(lookup(v, "has_secret", false)) }
  name        = "${local.tags["Project"]}-${each.key}-bsecret"
  description = "${each.key} (code)build secret"

  dynamic "replica" {
    for_each = local.is_production ? range(1) : []
    content {
      region = "us-east-1"
    }
  }

  tags = local.tags
  lifecycle {
    prevent_destroy = true
  }
}

locals {
  build_secrets = { for k, v in aws_secretsmanager_secret.build-secrets : k => v.name }
}
