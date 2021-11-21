resource "aws_vpc" "sellix-web-app-vpc" {
  cidr_block           = var.main_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = merge({
    "Name" = "${local.tags["Project"]}-vpc"
    },
    local.tags
  )
}

resource "aws_eip" "sellix-web-app-eip" {
  count = local.production ? length(local.availability_zones) : 1
  vpc   = "true"
  tags = merge({
    "Name" = "${local.tags["Project"]}-eip-${element(local.availability_zones, count.index)}"
    },
    local.tags
  )
  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_subnet" "sellix-web-app-public-subnet" {
  count             = local.production ? length(local.availability_zones) : 1
  vpc_id            = aws_vpc.sellix-web-app-vpc.id
  availability_zone = element(local.availability_zones, count.index)
  cidr_block = cidrsubnet(
    var.main_cidr_block,
    ceil(log(length(local.availability_zones) * 4, 2)),
    count.index
  )
  map_public_ip_on_launch = "true"
  tags = merge({
    "Name" = "${local.tags["Project"]}-public-subnet-${element(local.availability_zones, count.index)}"
    },
    local.tags
  )
}

resource "aws_subnet" "sellix-web-app-private-subnet" {
  count             = local.production ? length(local.availability_zones) : 1
  vpc_id            = aws_vpc.sellix-web-app-vpc.id
  availability_zone = element(local.availability_zones, count.index)
  cidr_block = cidrsubnet(
    var.main_cidr_block,
    ceil(log(length(local.availability_zones) * 4, 2)),
    length(local.availability_zones) + count.index
  )
  map_public_ip_on_launch = "false"
  tags = merge({
    "Name" = "${local.tags["Project"]}-private-subnet-${element(local.availability_zones, count.index)}"
    },
    local.tags
  )
}

resource "aws_nat_gateway" "sellix-web-app-nat-gateway" {
  count         = local.production ? length(local.availability_zones) : 1
  allocation_id = element(aws_eip.sellix-web-app-eip.*.id, count.index)
  subnet_id     = element(aws_subnet.sellix-web-app-public-subnet.*.id, count.index)
  tags = merge({
    "Name" = "${local.tags["Project"]}-nat-gateway-${element(local.availability_zones, count.index)}"
    },
    local.tags
  )
  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_internet_gateway" "sellix-web-app-internet-gateway" {
  vpc_id = aws_vpc.sellix-web-app-vpc.id
  tags = merge({
    "Name" = "${local.tags["Project"]}-internet-gateway"
    },
    local.tags
  )
}

resource "aws_route_table" "sellix-web-app-public-route-table" {
  vpc_id = aws_vpc.sellix-web-app-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sellix-web-app-internet-gateway.id
  }
  tags = merge({
    "Name" = "${local.tags["Project"]}-public-route-table"
    },
    local.tags
  )
}

resource "aws_route_table" "sellix-web-app-private-route-table" {
  count  = local.production ? length(local.availability_zones) : 1
  vpc_id = aws_vpc.sellix-web-app-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.sellix-web-app-nat-gateway.*.id, count.index)
  }
  lifecycle {
    create_before_destroy = "true"
  }
  tags = merge({
    "Name" = "${local.tags["Project"]}-private-route-table-${element(local.availability_zones, count.index)}"
    },
    local.tags
  )
}

resource "aws_route" "sellix-web-app-route" {
  route_table_id         = aws_route_table.sellix-web-app-public-route-table.id
  gateway_id             = aws_internet_gateway.sellix-web-app-internet-gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "sellix-web-app-public-route-table-association" {
  count          = local.production ? length(local.availability_zones) : 1
  subnet_id      = element(aws_subnet.sellix-web-app-public-subnet.*.id, count.index)
  route_table_id = aws_route_table.sellix-web-app-public-route-table.id
}

resource "aws_route_table_association" "sellix-web-app-private-route-table-association" {
  count          = local.production ? length(local.availability_zones) : 1
  subnet_id      = element(aws_subnet.sellix-web-app-private-subnet.*.id, count.index)
  route_table_id = local.production ? element(aws_route_table.sellix-web-app-private-route-table.*.id, count.index) : aws_route_table.sellix-web-app-private-route-table[0].id
}