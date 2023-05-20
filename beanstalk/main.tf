terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
    github = {
      source = "integrations/github"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}