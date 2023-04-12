terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    profile        = "sellix-terraform"
    bucket         = "sellix-deployments"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "sellix-deployments"
    key            = "eb-web-app.tfstate"
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

locals {
  is_production = length(regexall("production", terraform.workspace)) > 0
  environments  = { for k, v in var.environments : k => v if tobool(v.enabled) }
  is_redis      = length({ for k, v in local.environments : k => v if tobool(v.redis) }) > 0
  eu_main_cidr  = cidrsubnet(var.main_cidr_block, 8, ((local.is_production ? 0 : 2) + length(terraform.workspace)) % 256)
  us_main_cidr  = cidrsubnet(var.main_cidr_block, 8, (1 + length(terraform.workspace)) % 256)
  tags = {
    "Project"     = "sellix-eb-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
}

/* https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
data "aws_vpcs" "eb-vpcs" {
  tags = {
    service = "production"
  }
}
*/

module "vpc-eu-west-1" {
  source = "./vpc"
  providers = {
    aws = aws.eu-west-1
  }
  azs                   = var.preferred_azs
  tags                  = local.tags
  legacy-vpc-cidr-block = var.legacy-vpc-cidr-block
  legacy-vpc-sg         = var.legacy-vpc-sg
  main_cidr_block       = local.eu_main_cidr
  is_production         = local.is_production
  vpc_peerings          = var.vpc_peerings
}

module "vpc-us-east-1" {
  count  = local.is_production ? 1 : 0
  source = "./vpc"
  providers = {
    aws = aws.eu-west-1
  }
  azs                   = var.preferred_azs
  tags                  = local.tags
  legacy-vpc-cidr-block = var.legacy-vpc-cidr-block
  legacy-vpc-sg         = var.legacy-vpc-sg
  main_cidr_block       = local.us_main_cidr
  is_production         = local.is_production
  vpc_peerings          = var.vpc_peerings
}

module "eb-eu-west-1" {
  source = "./beanstalk"
  providers = {
    aws = aws.eu-west-1
  }
  tags                    = local.tags
  main_cidr_block         = local.eu_main_cidr
  vpc_id                  = module.vpc-eu-west-1.vpc_id
  vpc_subnets             = module.vpc-eu-west-1.subnets
  redis_endpoint          = local.is_redis ? one(module.redis-eu-west-1).writer : null
  redis_read_endpoint     = local.is_redis ? one(module.redis-eu-west-1).reader : null
  aws_access_key          = var.aws_access_key
  aws_secret_key          = var.aws_secret_key
  environments            = local.environments
  github_org              = var.github_org
  github_repos            = var.github_repos
  ssl_arn                 = var.ssl_arn
  codestar_connection_arn = var.codestar_connection_arn
  canary_deployments      = var.canary_deployments
  is_production           = local.is_production
  ssl_listener            = var.ssl_listener
}

// redis
module "eu-us-cross-region-vpc-peering" {
  count  = (local.is_production && local.is_redis) ? 1 : 0
  source = "./peering"
  providers = {
    aws.first  = aws.eu-west-1
    aws.second = aws.us-east-1
  }

  tags     = local.tags
  rts_1    = module.vpc-eu-west-1.rts["private"]
  vpc_id_1 = module.vpc-eu-west-1.vpc_id
  cidr_1   = local.eu_main_cidr

  rts_2    = one(module.vpc-us-east-1).rts["private"]
  vpc_id_2 = one(module.vpc-us-east-1).vpc_id
  cidr_2   = local.us_main_cidr
}

module "eb-us-east-1" {
  count  = local.is_production ? 1 : 0
  source = "./beanstalk"
  providers = {
    aws = aws.us-east-1
  }
  main_cidr_block         = local.us_main_cidr
  vpc_id                  = one(module.vpc-us-east-1).vpc_id
  vpc_subnets             = one(module.vpc-us-east-1).subnets
  tags                    = local.tags
  redis_endpoint          = local.is_redis ? one(module.redis-eu-west-1).writer : null
  redis_read_endpoint     = local.is_redis ? one(module.redis-us-east-1).reader : null
  aws_access_key          = var.aws_access_key
  aws_secret_key          = var.aws_secret_key
  environments            = local.environments
  github_org              = var.github_org
  github_repos            = var.github_repos
  ssl_arn                 = var.ssl_arn
  codestar_connection_arn = var.codestar_connection_arn
  canary_deployments      = var.canary_deployments
  is_production           = local.is_production
  ssl_listener            = var.ssl_listener
}

output "eu-west-1_eb-cname" {
  value = module.eb-eu-west-1.eb_cname
}

output "us-east-1_eb-cname" {
  value = one(module.eb-us-east-1).eb_cname
}
