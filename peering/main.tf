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

resource "aws_vpc_peering_connection" "sellix-eb-vpc-peering" {
  provider      = aws.first
  peer_owner_id = local.account_id
  peer_vpc_id   = var.vpc_id_1
  vpc_id        = var.vpc_id_2
  auto_accept   = true
  tags          = var.tags
}

resource "aws_security_group_rule" "sellix-eb-first-vpc-peering-security-group-rule" {
  provider          = aws.first
  security_group_id = var.sgr_id_1
  description       = "allow cross-region beanstalk vpc ingress traffic"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = [var.cidr_2]
}

resource "aws_security_group_rule" "sellix-eb-second-vpc-peering-security-group-rule" {
  provider          = aws.second
  security_group_id = var.sgr_id_2
  description       = "allow cross-region beanstalk vpc ingress traffic"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = [var.cidr_1]
}

resource "aws_route" "sellix-eb-first-cross-region-peering-route" {
  provider                  = aws.first
  count                     = length(var.rts_1)
  route_table_id            = var.rts_1[count.index].id
  destination_cidr_block    = var.cidr_2
  vpc_peering_connection_id = aws_vpc_peering_connection.sellix-eb-vpc-peering.id
}

resource "aws_route" "sellix-eb-second-cross-region-peering-route" {
  provider                  = aws.second
  count                     = length(var.rts_2)
  route_table_id            = var.rts_2[count.index].id
  destination_cidr_block    = var.cidr_1
  vpc_peering_connection_id = aws_vpc_peering_connection.sellix-eb-vpc-peering.id
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "rts_1" {
  type        = list(any)
  description = "beanstalk vpc first private subnets route tables id"
  default     = []
}

variable "rts_2" {
  type        = list(any)
  description = "beanstalk vpc second private subnets route tables id"
  default     = []
}

variable "vpc_id_1" {
  type        = string
  description = "beanstalk first vpc"
  default     = ""
}

variable "vpc_id_2" {
  type        = string
  description = "beanstalk second vpc"
  default     = ""
}

variable "cidr_1" {
  type        = string
  description = "beanstalk first cidr"
  default     = ""
}

variable "cidr_2" {
  type        = string
  description = "beanstalk second cidr"
  default     = ""
}

variable "sgr_id_1" {
  type    = string
  default = ""
}

variable "sgr_id_2" {
  type    = string
  default = ""
}