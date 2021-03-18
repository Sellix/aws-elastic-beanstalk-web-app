resource "aws_key_pair" "sellix-web-app-keypair" {
  key_name   = "sellix-web-app-${terraform.workspace}-keypair"
  public_key = file(var.public_key_path)
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

variable "github_oauth" {
  description = "GitHub OAUTH KEY"
  default     = "566b2a734f54dc4f40e756105e57819e826261e0"
}

variable "github_org" {
  description = "GitHub Organization/User"
  default     = "Sellix"
}

variable "github_repo" {
  description = "GitHub Repo Name"
  default     = "web-app"
}

variable "ssl_production_acm_arn" {
  description = "SSL Certificate ARN"
  default     = "arn:aws:acm:eu-west-1:671586216466:certificate/3bec7765-1c9a-4277-af3e-0aaa6283a3ed"
}

variable "ssl_staging_acm_arn" {
  description = "SSL Certificate ARN"
  default     = "arn:aws:acm:eu-west-1:671586216466:certificate/8e8d23d4-1c61-4d30-bfdd-6cb9b45e4c0a"
}