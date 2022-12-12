terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      "source" = "hashicorp/aws",
    }
  }
}

variable "is_primary" {
    type = bool
    default = false
}

variable "sgr_id" {
    type = string
}

variable "redis_node_type" {
    type = string
}

variable "subnet_ids" {
    type = list(string)
}

variable "global_replication_group_id" {
    type = any
    default = null
}

variable "tags" {
    type = map(any)
}

data "aws_region" "current" {}

resource "aws_elasticache_replication_group" "sellix-eb-redis" {
  transit_encryption_enabled  = true
  at_rest_encryption_enabled  = true
  replication_group_id        = "${var.tags["Project"]}-redis"
  description                 = "${var.tags["Project"]}-redis"
  engine                      = "redis"
  node_type                   = var.redis_node_type
  port                        = 6379
  security_group_ids          = [var.sgr_id]
  apply_immediately           = true
  automatic_failover_enabled  = true
  num_cache_clusters          = 2
  multi_az_enabled            = true
  subnet_group_name           = aws_elasticache_subnet_group.sellix-eb-redis-subnet-group.name
  auto_minor_version_upgrade  = true
  snapshot_retention_limit    = 30
  snapshot_window             = "04:30-05:30"
  global_replication_group_id = var.global_replication_group_id
  tags                        = var.tags
}

resource "aws_elasticache_subnet_group" "sellix-eb-redis-subnet-group" {
  name       = "${var.tags["Project"]}-redis-subnet-group"
  subnet_ids = var.subnet_ids //module.vpc-secondary.subnets[*].id
  tags       = var.tags
}

output "id" {
    value = aws_elasticache_replication_group.sellix-eb-redis.id
}

output "reader" {
    value = {"${data.aws_region.current.name}": aws_elasticache_replication_group.sellix-eb-redis.reader_endpoint_address}
}

output "writer" {
    value = var.is_primary ? aws_elasticache_replication_group.sellix-eb-redis.primary_endpoint_address : null
}