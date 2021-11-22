variable "aws_access_key" {
  default = null
}

variable "aws_secret_key" {
  default = null
}

variable "nodejs_version" {
  description = "Beanstalk Node.js Version"
  default     = null
}

variable "main_cidr_block" {
  description = "main cidr"
  default     = "172.0.0.0/8"
}

variable "legacy-vpc_cidr-block" {
  description = "legacy vpc cidr"
  default     = "10.192.0.0/16"
}

variable "github_opts" {
  description = "GitHub Repo Name && Organization"
  default     = {}
}

variable "ssl_arn" {
  description = "SSL Certificate ARN"
  default     = {}
}

variable "vpc_peerings" {
  description = "VPC Peering Ids"
  default     = {}
}

variable "codestar_connection_arn" {
  description = "CodeStar Connection ARN"
  default     = null
}