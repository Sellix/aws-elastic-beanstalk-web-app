resource "aws_key_pair" "web-app-keypair" {
  key_name   = "sellix-web-app-keypair"
  public_key = file("${var.public_key_path}")
  lifecycle {
    ignore_changes = [public_key]
  }
}

variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_region" {
  default = "eu-west-1"
}

variable "public_key_path" {
  description = "ssh key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "main_cidr_block" {
  description = "main cidr"
  default     = "172.18.0.0/16"
}

variable "public_cidr_block" {
  description = "public cidr"
  default     = "172.18.1.0/24"
}

variable "github_oauth" {
  description = "GitHub OAUTH KEY"
  default     = ""
}

variable "github_org" {
  description = "GitHub Organization/User"
  default     = "Sellix"
}

variable "github_repo" {
  description = "GitHub Repo Name"
  default     = "web-app"
}

variable "environment_check" {
  description = "staging or production"
  type        = string
  validation {
    condition = var.environment_check == "production" || var.environment_check == "staging"
    error_message = "Enviroment must be production or staging."
  }
}

variable "ssl_production_acm_arn" {
  description = "SSL Certificate ARN"
  default     = "arn:aws:acm:eu-west-1:671586216466:certificate/3bec7765-1c9a-4277-af3e-0aaa6283a3ed"
}

variable "ssl_staging_acm_arn" {
  description = "SSL Certificate ARN"
  default     = "arn:aws:acm:eu-west-1:671586216466:certificate/8e8d23d4-1c61-4d30-bfdd-6cb9b45e4c0a"
}