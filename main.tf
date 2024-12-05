terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
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

provider "cloudflare" {
  api_token = var.cloudflare-api-token
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
  environments  = { for k, v in var.environments : k => v if tobool(lookup(v, "enabled", false)) }
  multi_region_environments = (
    local.is_production ? {
      for k, v in local.environments :
      k => v
      if tobool(lookup(v, "multi_region", false))
    } : {}
  )

  is_peering = anytrue([for k, v in local.environments : tobool(lookup(v, "peering", false))])
  is_redis   = anytrue([for k, v in local.environments : tobool(lookup(v, "redis", false))])

  eu_main_cidr = var.subnets[0]
  us_main_cidr = local.is_production && can(var.subnets[1]) ? var.subnets[1] : ""

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
  azs             = var.preferred_azs
  tags            = local.tags
  main_cidr_block = local.eu_main_cidr
  is_production   = local.is_production
}

module "vpc-us-east-1" {
  count  = (length(local.multi_region_environments) > 0) && local.is_production ? 1 : 0
  source = "./vpc"
  providers = {
    aws = aws.us-east-1
  }
  azs             = var.preferred_azs
  tags            = local.tags
  main_cidr_block = local.us_main_cidr
  is_production   = local.is_production
}

module "eb-to-legacy_alb-eu-peering" {
  count  = local.is_peering && local.is_production ? 1 : 0
  source = "./peering"
  providers = {
    aws.first  = aws.eu-west-1,
    aws.second = aws.eu-west-1
  }

  tags     = local.tags
  rts_1    = var.legacy-vpc.rts_id
  vpc_id_1 = one(var.legacy-vpc.vpc_id)

  rts_2    = module.vpc-eu-west-1.rts["private"]
  vpc_id_2 = module.vpc-eu-west-1.vpc_id
}

module "eb-to-legacy_alb-us-peering" {
  count  = (length(local.multi_region_environments) > 0) && local.is_peering && local.is_production ? 1 : 0
  source = "./peering"
  providers = {
    aws.first  = aws.eu-west-1,
    aws.second = aws.us-east-1
  }

  tags     = local.tags
  rts_1    = var.legacy-vpc.rts_id
  vpc_id_1 = one(var.legacy-vpc.vpc_id)

  rts_2    = one(module.vpc-us-east-1).rts["private"]
  vpc_id_2 = one(module.vpc-us-east-1).vpc_id
}

module "eb-eu-west-1" {
  source = "./beanstalk"
  providers = {
    aws        = aws.eu-west-1
    cloudflare = cloudflare
  }
  tags            = local.tags
  main_cidr_block = local.eu_main_cidr
  vpc_id          = module.vpc-eu-west-1.vpc_id
  vpc_subnets     = module.vpc-eu-west-1.subnets
  redis_endpoint = (local.is_redis ?   //(local.is_production ?
    one(module.redis-eu-west-1).writer //:
    //one(module.redis-staging).NLB-endpoint)
  : "")
  redis_read_endpoint = (local.is_redis ? //(local.is_production ?
    one(module.redis-eu-west-1).reader    //:
    //one(module.redis-staging).NLB-endpoint)
  : "")
  aws_access_key          = var.aws_access_key
  aws_secret_key          = var.aws_secret_key
  environments            = local.environments
  ssl_arn                 = var.ssl_arn
  codestar_connection_arn = var.codestar_connection_arn
  canary_deployments      = var.canary_deployments
  is_production           = local.is_production
  ssl_listener            = var.ssl_listener
  cloudflare_enabled      = var.cloudflare_enabled
  build_secrets           = local.build_secrets
  cloudwatch_logs_days = var.cloudwatch_logs_days
}

// redis
module "eu-us-cross-region-vpc-peering" {
  count = ((length(local.multi_region_environments) > 0)
  && local.is_production && local.is_redis) ? 1 : 0
  source = "./peering"
  providers = {
    aws.first  = aws.eu-west-1
    aws.second = aws.us-east-1
  }

  tags     = local.tags
  rts_1    = module.vpc-eu-west-1.rts["private"]
  vpc_id_1 = module.vpc-eu-west-1.vpc_id

  rts_2    = one(module.vpc-us-east-1).rts["private"]
  vpc_id_2 = one(module.vpc-us-east-1).vpc_id
}

module "eb-us-east-1" {
  count  = (length(local.multi_region_environments) > 0) && local.is_production ? 1 : 0
  source = "./beanstalk"
  providers = {
    aws        = aws.us-east-1
    cloudflare = cloudflare
  }
  main_cidr_block         = local.us_main_cidr
  vpc_id                  = one(module.vpc-us-east-1).vpc_id
  vpc_subnets             = one(module.vpc-us-east-1).subnets
  tags                    = local.tags
  redis_endpoint          = local.is_redis ? one(module.redis-eu-west-1).writer : ""
  redis_read_endpoint     = local.is_redis ? one(module.redis-us-east-1).reader : ""
  aws_access_key          = var.aws_access_key
  aws_secret_key          = var.aws_secret_key
  environments            = local.multi_region_environments
  ssl_arn                 = var.ssl_arn
  codestar_connection_arn = var.codestar_connection_arn
  canary_deployments      = var.canary_deployments
  is_production           = local.is_production
  ssl_listener            = var.ssl_listener
  cloudflare_enabled      = var.cloudflare_enabled
  build_secrets           = local.build_secrets
  cloudwatch_logs_days = var.cloudwatch_logs_days
}

output "eu-west-1_eb-cname" {
  value = module.eb-eu-west-1.eb_cname
}

output "us-east-1_eb-cname" {
  value = module.eb-us-east-1[*].eb_cname
}

output "global_accelerator-cname" {
  value = {
    for env_name, v in aws_globalaccelerator_accelerator.production-ga :
    env_name => v.dns_name
  }
}

output "eu-west-1_ecr" {
  value = module.eb-eu-west-1.ecr
}

output "us-east-1_ecr" {
  value = module.eb-us-east-1[*].ecr
}