resource "aws_elasticache_replication_group" "sellix-eb-redis" {
  replication_group_id       = "${local.tags["Project"]}-redis"
  engine                     = "redis"
  node_type                  = var.is_production ? "cache.t3.medium" : "cache.t4g.small"
  port                       = 6379
  security_group_ids         = [aws_security_group.sellix-eb-security-group.id]
  apply_immediately          = true
  automatic_failover_enabled = false
  #  preferred_cache_cluster_azs = ["us-west-2a", "us-west-2b"]
  num_cache_clusters = 1
  description        = "-"
  multi_az_enabled   = false
  subnet_group_name  = aws_elasticache_subnet_group.sellix-eb-redis-subnet-group.name
  tags               = local.tags
}

resource "aws_elasticache_subnet_group" "sellix-eb-redis-subnet-group" {
  name       = "${local.tags["Project"]}-redis-subnet-group"
  subnet_ids = aws_subnet.sellix-eb-private-subnet[*].id
  tags       = local.tags
}
