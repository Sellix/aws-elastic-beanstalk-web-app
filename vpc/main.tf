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
  filter {
    name   = "opt-in-status"
    values = ["opted-in", "opt-in-not-required"]
  }
}

data "aws_region" "current" {}

locals {
  aws_region = data.aws_region.current.name

  legacy-peering-conn-id = lookup(var.vpc_peerings[local.aws_region], terraform.workspace, "")
  is_peering             = length(local.legacy-peering-conn-id) > 0

  availability_zones = [
    for az in var.azs : format("%s%s", local.aws_region, az)
  ]
  /*
  // intersection between user azs and available azs
  filtered_azs = tolist(setintersection(
    toset([
      for az in var.azs : format("%s%s", local.aws_region, az)
    ]),
    toset(data.aws_availability_zones.available.names))
  )
  remaining_azs = tolist(setsubtract(
    toset(data.aws_availability_zones.available.names),
    toset(local.filtered_azs)
  ))
  // see if user azs are available else add random azs
  availability_zones = (length(local.filtered_azs) == length(var.azs) ?
    local.filtered_azs :
    concat([
      for _, j in range(length(var.azs) - length(local.filtered_azs) % length(local.remaining_azs)) :
      local.remaining_azs[j]
      ],
    local.filtered_azs)
  )
  */
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "azs" {
  type        = list(string)
  description = "chosen azs"
  default     = []
}

variable "legacy-vpc-cidr-block" {
  type        = string
  description = "legacy vpc cidr"
  default     = null
}

variable "legacy-vpc-sg" {
  type        = string
  description = "legacy vpc sg id"
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
    "public" : aws_subnet.sellix-eb-public-subnet[*].id,
    "private" : aws_subnet.sellix-eb-private-subnet[*].id
  }
}

output "rts" {
  value = {
    "public" : aws_route_table.sellix-eb-public-route-table[*].id,
    "private" : aws_route_table.sellix-eb-private-route-table[*].id
  }
}

output "azs" {
  value = local.availability_zones
}