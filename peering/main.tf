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

data "aws_vpc" "vpc_1" {
  provider = aws.first
  id       = var.vpc_id_1
}

data "aws_vpc" "vpc_2" {
  provider = aws.second
  id       = var.vpc_id_2
}

data "aws_caller_identity" "first-ci" {
  provider = aws.first
}

data "aws_region" "first" {
  provider = aws.first
}

locals {
  account_id = data.aws_caller_identity.first-ci.account_id
}

resource "aws_vpc_peering_connection" "sellix-vpc-peering" {
  provider = aws.second

  peer_owner_id = local.account_id
  peer_vpc_id   = var.vpc_id_1
  peer_region   = data.aws_region.first.name

  vpc_id      = var.vpc_id_2
  auto_accept = false

  tags = merge({
    Name = "${var.tags["Project"]}-peering"
    },
  var.tags)
}

resource "aws_vpc_peering_connection_accepter" "sellix-vpc-peering-accepter" {
  provider                  = aws.first
  vpc_peering_connection_id = aws_vpc_peering_connection.sellix-vpc-peering.id

  auto_accept = true

  tags = merge({
    Name = "${var.tags["Project"]}-peering"
    Side = "Accepter"
    },
  var.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route" "sellix-first-cross-region-peering-route" {
  provider                  = aws.first
  count                     = length(var.rts_1)
  route_table_id            = var.rts_1[count.index]
  destination_cidr_block    = data.aws_vpc.vpc_2.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.sellix-vpc-peering.id
}

resource "aws_route" "sellix-second-cross-region-peering-route" {
  provider                  = aws.second
  count                     = length(var.rts_2)
  route_table_id            = var.rts_2[count.index]
  destination_cidr_block    = data.aws_vpc.vpc_1.cidr_block
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
