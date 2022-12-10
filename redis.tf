resource "aws_elasticache_replication_group" "sellix-eb-redis-eu" {
  provider                   = aws.eu-west-1
  replication_group_id       = "${local.tags["Project"]}-redis"
  description                = "${local.tags["Project"]}-redis"
  engine                     = "redis"
  node_type                  = local.is_production ? "cache.t3.medium" : "cache.t4g.small"
  port                       = 6379
  security_group_ids         = [module.vpc-eu-west-1.sgr["eb"].id]
  apply_immediately          = true
  automatic_failover_enabled = false
  num_cache_clusters         = 1
  multi_az_enabled           = false
  subnet_group_name          = aws_elasticache_subnet_group.sellix-eb-redis-subnet-group-eu.name
  tags                       = local.tags
}

resource "aws_elasticache_global_replication_group" "sellix-eb-global-datastore" {
  provider                           = aws.eu-west-1
  count                              = local.is_production ? 1 : 0
  global_replication_group_id_suffix = "sellix-eb-global-datastore"
  primary_replication_group_id       = aws_elasticache_replication_group.sellix-eb-redis-eu.id
}

resource "aws_elasticache_replication_group" "sellix-eb-redis-us" {
  provider                    = aws.us-east-1
  count                       = local.is_production ? 1 : 0
  replication_group_id        = "${local.tags["Project"]}-redis"
  description                 = "${local.tags["Project"]}-redis"
  engine                      = "redis"
  node_type                   = local.is_production ? "cache.t3.medium" : "cache.t4g.small"
  port                        = 6379
  security_group_ids          = [module.vpc-us-east-1[count.index].sgr["eb"].id]
  apply_immediately           = true
  automatic_failover_enabled  = false
  num_cache_clusters          = 1
  multi_az_enabled            = false
  subnet_group_name           = aws_elasticache_subnet_group.sellix-eb-redis-subnet-group-us[count.index].name
  tags                        = local.tags
  global_replication_group_id = aws_elasticache_global_replication_group.sellix-eb-global-datastore[*].global_replication_group_id
}

resource "aws_elasticache_subnet_group" "sellix-eb-redis-subnet-group-eu" {
  provider   = aws.eu-west-1
  name       = "${local.tags["Project"]}-redis-subnet-group"
  subnet_ids = module.vpc-eu-west-1.subnets["private"][*].id
  tags       = local.tags
}

resource "aws_elasticache_subnet_group" "sellix-eb-redis-subnet-group-us" {
  provider   = aws.us-east-1
  count      = local.is_production ? 1 : 0
  name       = "${local.tags["Project"]}-redis-subnet-group"
  subnet_ids = module.vpc-us-east-1[count.index].subnets["private"][*].id
  tags       = local.tags
}