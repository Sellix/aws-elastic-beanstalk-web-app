resource "aws_security_group" "sellix-redis-eu-west-1-sg" {
  count       = local.is_redis ? 1 : 0
  provider    = aws.eu-west-1
  name        = "Redis eu-west-1 Security Group"
  description = "Redis Traffic SG"
  vpc_id      = module.vpc-eu-west-1.vpc_id
  ingress {
    description = "Allow Redis Connections"
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = [local.eu_main_cidr]
  }
  egress {
    description = "consent Redis updates"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.tags,
    {
      "Name" : "${local.tags["Project"]}-redis-security-group"
    }
  )
}

resource "aws_security_group" "sellix-redis-us-east-1-sg" {
  count       = (local.is_production && local.is_redis) ? 1 : 0
  provider    = aws.us-east-1
  name        = "Redis us-east-1 Security Group"
  description = "Redis Traffic SG"
  vpc_id      = one(module.vpc-us-east-1).vpc_id
  ingress {
    description = "Allow Redis Connections"
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = [local.us_main_cidr]
  }
  egress {
    description = "consent Redis updates"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.tags,
    {
      "Name" : "${local.tags["Project"]}-redis-security-group"
    }
  )
}

module "redis-eu-west-1" {
  count  = local.is_redis ? 1 : 0
  source = "./redis-regions"
  providers = {
    aws = aws.eu-west-1
  }
  is_primary                 = true
  is_production              = local.is_production
  tags                       = local.tags
  sgr_id                     = one(aws_security_group.sellix-redis-eu-west-1-sg).id
  node_type                  = local.is_production ? "cache.t3.medium" : "cache.t4g.small"
  subnet_ids                 = local.is_production ? module.vpc-eu-west-1.subnets["private"][*] : module.vpc-eu-west-1.subnets["public"][*]
  port                       = var.redis_port
  num_cache_cluster          = local.is_production ? 2 : 1
  snapshot_retention_limit   = local.is_production ? 30 : 0
  transit_encryption_enabled = var.redis_transit_encryption_enabled
}

resource "aws_elasticache_global_replication_group" "sellix-eb-global-datastore" {
  count                              = (local.is_production && local.is_redis) ? 1 : 0
  provider                           = aws.eu-west-1
  global_replication_group_id_suffix = "sellix-eb-global-datastore"
  primary_replication_group_id       = one(module.redis-eu-west-1).id
}

module "redis-us-east-1" {
  count  = (local.is_production && local.is_redis) ? 1 : 0
  source = "./redis-regions"
  providers = {
    aws = aws.us-east-1
  }
  is_primary                  = false
  is_production               = local.is_production
  tags                        = local.tags
  sgr_id                      = one(aws_security_group.sellix-redis-us-east-1-sg).id
  node_type                   = "cache.t3.medium"
  subnet_ids                  = one(module.vpc-us-east-1).subnets["private"][*]
  global_replication_group_id = one(aws_elasticache_global_replication_group.sellix-eb-global-datastore).id
  port                        = var.redis_port
}

