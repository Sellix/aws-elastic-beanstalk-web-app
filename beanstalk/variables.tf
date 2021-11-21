resource "aws_key_pair" "sellix-web-app-keypair" {
  key_name   = "${local.tags["Project"]}-keypair"
  public_key = file(var.public_key_path)
  lifecycle {
    ignore_changes = [public_key]
  }
}

variable "aws_access_key" {
  default = null
}

variable "aws_secret_key" {
  default = null
}

variable "aws_region" {
  default = null
}

variable "public_key_path" {
  description = "ssh key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "nodejs_version" {
  description = "Beanstalk Node.js Version"
  default     = null
}

variable "main_cidr_block" {
  description = "main cidr"
  default     = "172.18.0.0/16"
}

variable "github_opts" {
  description = "GitHub Repo Name && Organization"
  default     = {}
}

variable "ssl_arn" {
  description = "SSL Certificate ARN"
  default     = {}
}

variable "codestar_connection_arn" {
  description = "CodeStar Connection ARN"
  default     = null
}