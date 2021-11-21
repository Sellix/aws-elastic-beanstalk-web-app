terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      "source" = "hashicorp/aws"
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
  is_production = contains(["prod"], substr(terraform.workspace, 0, 4))
}

module "eu-west-1" {
  source = "./beanstalk"
  providers = {
    aws = aws.eu-west-1
  }
  aws_access_key          = var.aws_access_key
  aws_secret_key          = var.aws_secret_key
  nodejs_version          = var.nodejs_version
  aws_region              = "eu-west-1"
  github_opts             = var.github_opts
  ssl_arn                 = var.ssl_arn
  codestar_connection_arn = var.codestar_connection_arn
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
  aws_region              = "us-east-1"
  nodejs_version          = var.nodejs_version
  github_opts             = var.github_opts
  ssl_arn                 = var.ssl_arn
  codestar_connection_arn = var.codestar_connection_arn
  is_production           = local.is_production
}

output "eu-west-1_eb-cname" {
  value = module.eu-west-1.eb_cname
}

output "us-east-1_eb-cname" {
  value = module.us-east-1.*.eb_cname
}