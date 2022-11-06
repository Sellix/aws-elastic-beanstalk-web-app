terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
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
}

/* https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
data "aws_vpcs" "eb-vpcs" {
  tags = {
    service = "production"
  }
}
*/

module "eu-west-1" {
  source = "./beanstalk"
  providers = {
    aws = aws.eu-west-1
  }
  aws_access_key          = var.aws_access_key
  aws_secret_key          = var.aws_secret_key
  main_cidr_block         = cidrsubnet(var.main_cidr_block, 8, (local.is_production ? 0 : 2) + length(terraform.workspace))
  legacy-vpc_cidr-block   = var.legacy-vpc_cidr-block
  aws_region              = "eu-west-1"
  domains                 = var.domains
  environments            = local.environments
  github_org              = var.github_org
  github_repos            = var.github_repos
  ssl_arn                 = var.ssl_arn
  vpc_peerings            = var.vpc_peerings
  codestar_connection_arn = var.codestar_connection_arn
  canary_deployments      = var.canary_deployments
  is_production           = local.is_production
}

module "us-east-1" {
  count  = local.is_production ? 1 : 0
  source = "./beanstalk"
  providers = {
    aws = aws.us-east-1
  }
  aws_access_key          = var.aws_access_key
  aws_secret_key          = var.aws_secret_key
  main_cidr_block         = cidrsubnet(var.main_cidr_block, 8, 1)
  legacy-vpc_cidr-block   = var.legacy-vpc_cidr-block
  aws_region              = "us-east-1"
  domains                 = var.domains
  environments            = local.environments
  github_org              = var.github_org
  github_repos            = var.github_repos
  ssl_arn                 = var.ssl_arn
  vpc_peerings            = var.vpc_peerings
  codestar_connection_arn = var.codestar_connection_arn
  canary_deployments      = var.canary_deployments
  is_production           = local.is_production
}

output "eu-west-1_eb-cname" {
  value = module.eu-west-1[*].eb_cname
}

output "us-east-1_eb-cname" {
  value = module.us-east-1[*].eb_cname
}
