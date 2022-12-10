terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      "source" = "hashicorp/aws"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

locals {
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  aws_region         = data.aws_region.current.name
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "legacy-vpc_cidr-block" {
  type        = string
  description = "legacy vpc cidr"
  default     = null
}

variable "main_cidr_block" {
  type        = string
  description = "main cidr"
  default     = null
}

variable "is_production" {
  type        = bool
  description = "Environment Boolean"
  default     = true
}

variable "vpc_peerings" {
  type        = map(any)
  description = "VPC Peering Ids"
  default     = {}
}

output "vpc_id" {
  value = aws_vpc.sellix-eb-vpc.id
}

output "subnets" {
  value = {
    "public" : aws_subnet.sellix-eb-public-subnet[*],
    "private" : aws_subnet.sellix-eb-private-subnet[*]
  }
}

output "sgr" {
  value = {
    "eb" : aws_security_group.sellix-eb-security-group,
    "elb" : aws_security_group.sellix-eb-elb-security-group
  }
}

output "rts" {
  value = aws_route_table.sellix-eb-private-route-table[*]
}