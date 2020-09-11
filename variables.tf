resource "aws_key_pair" "sellix-web-app-keypair" {
  key_name   = "sellix-web-app-keypair"
  public_key = file("${var.public_key_path}")
  lifecycle {
    ignore_changes = [public_key]
  }
}

variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "AWS_REGION" {
  default = "eu-west-1"
}

variable "public_key_path" {
  description = "SSH KEY"
  default     = "~/.ssh/id_rsa.pub"
}

variable "main_cidr_block" {
  description = "MAIN CIDR"
  default     = "172.18.0.0/16"
}

variable "public_cidr_block" {
  description = "PUBLIC CIDR"
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

variable "env_vars" {
  type    = map(string)
  default = {
    ELASTIC_BEANSTALK_PORT  = 8080
  }
}