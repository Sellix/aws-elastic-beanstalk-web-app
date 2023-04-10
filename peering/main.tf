terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      "source" = "hashicorp/aws",
      configuration_aliases = [
        aws.first,
        aws.second,
      ]
    }
  }
}

data "aws_region" "current" {
  provider = aws.first
}

data "aws_caller_identity" "current" {
  provider = aws.first
}

locals {
  aws_region = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_vpc_peering_connection" "sellix-vpc-peering" {
  provider      = aws.first
  peer_owner_id = local.account_id
  peer_vpc_id   = var.vpc_id_1
  vpc_id        = var.vpc_id_2
  auto_accept   = true
  tags          = var.tags
}

resource "aws_route" "sellix-first-cross-region-peering-route" {
  provider                  = aws.first
  count                     = length(var.rts_1)
  route_table_id            = var.rts_1[count.index]
  destination_cidr_block    = var.cidr_2
  vpc_peering_connection_id = aws_vpc_peering_connection.sellix-vpc-peering.id
}

resource "aws_route" "sellix-second-cross-region-peering-route" {
  provider                  = aws.second
  count                     = length(var.rts_2)
  route_table_id            = var.rts_2[count.index]
  destination_cidr_block    = var.cidr_1
  vpc_peering_connection_id = aws_vpc_peering_connection.sellix-vpc-peering.id
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "rts_1" {
  type        = list(any)
  description = "first vpc private subnets route tables id"
  default     = []
}

variable "rts_2" {
  type        = list(any)
  description = "second vpc private subnets route tables id"
  default     = []
}

variable "vpc_id_1" {
  type        = string
  description = "first vpc"
  default     = ""
}

variable "vpc_id_2" {
  type        = string
  description = "second vpc"
  default     = ""
}

variable "cidr_1" {
  type        = string
  description = "first cidr"
  default     = ""
}

variable "cidr_2" {
  type        = string
  description = "second cidr"
  default     = ""
}
