terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      "source" = "hashicorp/aws",
    }
  }
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "main_cidr_block" {
  type        = string
  description = "main cidr"
  default     = null
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
}

resource "aws_vpc" "sellix-eb-redis-vpc" {
  cidr_block           = var.main_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge({
    "Name" = "${var.tags["Project"]}-vpc"
    },
    var.tags
  )
}

resource "aws_subnet" "sellix-eb-redis-private-subnet" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.sellix-eb-redis-vpc.id
  availability_zone = element(local.availability_zones, count.index)
  cidr_block = cidrsubnet(
    var.main_cidr_block,
    8,
    count.index
  )
  map_public_ip_on_launch = "false"
  tags = merge({
    "Name" = "${var.tags["Project"]}-private-subnet-${element(local.availability_zones, count.index)}"
    },
    var.tags
  )
}

resource "aws_route_table" "sellix-eb-redis-private-route-table" {
  count  = length(local.availability_zones)
  vpc_id = aws_vpc.sellix-eb-redis-vpc.id
  lifecycle {
    create_before_destroy = "true"
  }
  tags = merge({
    "Name" = "${var.tags["Project"]}-private-route-table-${element(local.availability_zones, count.index)}"
    },
    var.tags
  )
}

resource "aws_route_table_association" "sellix-eb-redis-private-route-table-association" {
  count          = length(local.availability_zones)
  subnet_id      = element(aws_subnet.sellix-eb-redis-private-subnet[*].id, count.index)
  route_table_id = element(aws_route_table.sellix-eb-redis-private-route-table[*].id, count.index)
}

resource "aws_security_group" "sellix-eb-redis-security-group" {
  name        = "${var.tags["Project"]}-security-group"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.sellix-eb-redis-vpc.id
  tags = merge({
    "Name" = "${var.tags["Project"]}-security-group"
    },
    var.tags
  )
}

output "vpc_id" {
  value = aws_vpc.sellix-eb-redis-vpc.id
}

output "subnets" {
  value = aws_subnet.sellix-eb-redis-private-subnet[*]
}

output "sgr" {
  value = aws_security_group.sellix-eb-redis-security-group
}

output "rts" {
  value = aws_route_table.sellix-eb-redis-private-route-table[*]
}