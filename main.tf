terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      "source" = "hashicorp/aws"
    }
    github = {
      source = "integrations/github"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  backend "s3" {
    bucket         = "sellix-deployments"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "sellix-deployments"
    key            = "eb-web-app.tfstate"
  }
}

provider "aws" {
  profile    = "sellix-terraform"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}