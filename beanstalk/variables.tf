resource "aws_key_pair" "sellix-eb-keypair" {
  key_name   = "${var.tags["Project"]}-keypair"
  public_key = file(var.public_key_path)
  lifecycle {
    ignore_changes = [public_key]
  }
}

variable "main_cidr_block" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "vpc_subnets" {
  type    = map(any)
  default = {}
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "redis_endpoint" {
  type = string
}

variable "redis_read_endpoint" {
  type = string
}

variable "aws_access_key" {
  type    = string
  default = null
}

variable "aws_secret_key" {
  type    = string
  default = null
}

variable "public_key_path" {
  type        = string
  description = "ssh key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "github_org" {
  type        = string
  description = "GitHub Organization Name"
  default     = null
}

variable "github_repos" {
  type        = map(any)
  description = "GitHub Repo Name"
  default     = {}
}

variable "ssl_arn" {
  type        = map(any)
  description = "SSL Certificate ARN"
  default     = {}
}

variable "codestar_connection_arn" {
  type        = string
  description = "CodeStar Connection ARN"
  default     = null
}

variable "canary_deployments" {
  type        = bool
  description = "Enables canary deployments through TG, ALB stickiness and EB traffic splitting"
  default     = null
}

variable "environments" {
  type        = map(any)
  description = "Environments"
  default     = null
}

variable "is_production" {
  type        = bool
  description = "Environment Boolean"
  default     = true
}

variable "ssl_listener" {
  type        = bool
  description = "Application Listens SSL"
  default     = true
}