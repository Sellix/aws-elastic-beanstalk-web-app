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
  default     = "172.16.0.0/12"
}

variable "subnets" {
  type        = list(string)
  description = "multi-region subnets"
  default     = ["172.16.0.0/16", "172.17.0.0/16"]
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

variable "cloudflare-api-token" {
  type        = string
  description = "cloudflare api token with IP PREFIXES Read"
  default     = ""
}

variable "cloudflare_enabled" {
  type        = bool
  description = "restrict incoming traffic"
  default     = false
}

variable "redis_node_types" {
  type        = map(string)
  description = "node types"
  default = {
    true : "cache.r6g.large",
    false : "cache.t4g.small"
  }
}

variable "cloudwatch_logs_days" {
  type = object({
    instance = optional(number),
    healthd  = optional(number)
  })
  description = "maximum number of days to retain CloudWatch logs"
  default = {
    "instance" : 90,
    "healthd" : 7,
  }
}

variable "slack_channel_names" {
  type = object({
    codepipeline = string,
    beanstalk    = string
  })
  nullable = true
  default = {
    "codepipeline" : null,
    "beanstalk" : null
  }
}
