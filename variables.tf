variable "aws_access_key" {
  type    = string
  default = null
}

variable "aws_secret_key" {
  type    = string
  default = null
}

variable "main_cidr_block" {
  type        = string
  description = "main cidr"
  default     = "172.0.0.0/8"
}

variable "legacy-vpc-sg" {
  type        = string
  description = "legacy vpc sg id"
  default     = "sg-0e0341d00f96b7cc0"
}

variable "ssl_arn" {
  type        = map(any)
  description = "SSL Certificate ARN"
  default     = {}
}

/*
variable "vpc_peerings" {
  type        = map(any)
  description = "VPC Peering Ids"
  default     = {}
}
*/

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

variable "redis_port" {
  type        = number
  description = "Redis listening port"
  default     = 6379
}

variable "redis_transit_encryption_enabled" {
  type        = bool
  description = "Redis transit encryption"
  default     = true
}

variable "ssl_listener" {
  type        = bool
  description = "Application Listens SSL"
  default     = true
}

variable "preferred_azs" {
  type        = list(string)
  description = "List of preferred azs"
  default     = ["b", "c"]
}

variable "legacy-vpc" {
  type        = map(any)
  description = "Legacy Infos"
  default     = null
}