terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 5.0"
    }
  }
}

variable "is_primary" {
  type    = bool
  default = false
}

variable "sgr_id" {
  type = string
}

variable "node_type" {
  type    = string
  default = ""
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "global_replication_group_id" {
  type    = any
  default = null
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "port" {
  type    = number
  default = 6379
}

variable "is_production" {
  type    = bool
  default = false
}

variable "num_cache_cluster" {
  type    = number
  default = 2
}

variable "snapshot_retention_limit" {
  type    = number
  default = 30
}

variable "transit_encryption_enabled" {
  type    = bool
  default = true
}

data "aws_region" "current" {}

resource "aws_elasticache_replication_group" "sellix-eb-redis" {
  transit_encryption_enabled  = var.is_primary ? var.transit_encryption_enabled : null
  at_rest_encryption_enabled  = var.is_primary ? true : null
  replication_group_id        = "${var.tags["Project"]}-redis"
  description                 = "${var.tags["Project"]}-redis"
  engine                      = var.is_primary ? "redis" : null
  node_type                   = var.is_primary ? var.node_type : null
  port                        = var.port
  security_group_ids          = [var.sgr_id]
  apply_immediately           = true
  automatic_failover_enabled  = var.is_production
  num_cache_clusters          = var.num_cache_cluster
  multi_az_enabled            = var.is_primary ? var.is_production : null
  subnet_group_name           = aws_elasticache_subnet_group.sellix-eb-redis-subnet-group.name
  // todo: fix
  // auto_minor_version_upgrade  = var.is_primary ? true : null
  snapshot_retention_limit    = var.snapshot_retention_limit
  snapshot_window             = "04:30-05:30"
  global_replication_group_id = var.global_replication_group_id
  tags = merge(var.tags,
    {
      "Name" : "${var.tags["Project"]}-${data.aws_region.current.name}-redis"
  })
}

resource "aws_elasticache_subnet_group" "sellix-eb-redis-subnet-group" {
  name       = "${var.tags["Project"]}-redis-subnet-group"
  subnet_ids = var.subnet_ids
  tags = merge(var.tags,
    {
      "Name" : "${var.tags["Project"]}-redis-subnet-group"
  })
}

output "id" {
  value = aws_elasticache_replication_group.sellix-eb-redis.id
}

output "reader" {
  value = aws_elasticache_replication_group.sellix-eb-redis.reader_endpoint_address
}

output "writer" {
  value = var.is_primary ? aws_elasticache_replication_group.sellix-eb-redis.primary_endpoint_address : null
}

output "member_clusters" {
  value = aws_elasticache_replication_group.sellix-eb-redis.member_clusters
}