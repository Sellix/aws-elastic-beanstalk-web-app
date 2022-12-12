terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      "source" = "hashicorp/aws",
    }
  }
  backend "s3" {
    profile        = "sellix-terraform"
    bucket         = "sellix-deployments"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "sellix-deployments"
    key            = "eb-redis.tfstate"
  }
}

provider "aws" {
  alias      = "eu-west-1"
  profile    = "sellix-terraform"
  region     = "eu-west-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "aws" {
  alias      = "us-east-1"
  profile    = "sellix-terraform"
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

variable "aws_access_key" {
  type    = string
  default = null
}

variable "aws_secret_key" {
  type    = string
  default = null
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.medium"
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "main_cidr_block" {
  type        = string
  description = "main cidr"
  default     = null
}

locals {
  cidr = "10.0.0.0/8"
}
module "vpc-primary" {
  source = "./vpc"
  providers = {
    aws = aws.eu-west-1
  }
  main_cidr_block = cidrsubnet(local.cidr, 8, 0)
  tags            = var.tags
}

module "vpc-secondary" {
  source = "./vpc"
  providers = {
    aws = aws.us-east-1
  }
  main_cidr_block = cidrsubnet(local.cidr, 8, 1)
  tags            = var.tags
}

module "primary-secondary-cross-region-vpc-peering" {
  source = "../peering"
  providers = {
    aws.first  = aws.eu-west-1
    aws.second = aws.us-east-1
  }
  tags     = var.tags
  rts_1    = module.vpc-primary.rts
  vpc_id_1 = module.vpc-primary.vpc_id
  cidr_1   = cidrsubnet(local.cidr, 8, 0)
  sgr_id_1 = module.vpc-primary.sgr

  rts_2    = module.vpc-secondary.rts
  vpc_id_2 = module.vpc-secondary.vpc_id
  cidr_2   = cidrsubnet(local.cidr, 8, 1)
  sgr_id_2 = module.vpc-secondary.sgr
}

module "primary-redis" {
  source = "./redis-regions"
  providers = {
    aws = aws.eu-west-1
  }
  is_primary      = true
  tags            = var.tags
  sgr_id          = module.vpc-primary.sgr
  redis_node_type = var.redis_node_type
  subnet_ids      = module.vpc-primary.subnets[*].id
}

resource "aws_elasticache_global_replication_group" "sellix-eb-global-datastore" {
  provider                           = aws.eu-west-1
  global_replication_group_id_suffix = "sellix-eb-global-datastore"
  primary_replication_group_id       = module.primary-redis.id
}

module "secondary-redis" {
  source = "./redis-regions"
  providers = {
    aws = aws.us-east-1
  }
  is_primary                  = false
  tags                        = var.tags
  sgr_id                      = module.vpc-secondary.sgr
  redis_node_type             = var.redis_node_type
  subnet_ids                  = module.vpc-secondary.subnets[*].id
  global_replication_group_id = aws_elasticache_global_replication_group.sellix-eb-global-datastore.id
}

output "readers" {
  value = merge(
    module.secondary-redis.reader
  )
}

output "writer" {
  value = module.primary-redis.writer
}

