resource "aws_vpc" "sellix-web-app-vpc" {
  cidr_block            = var.main_cidr_block
  instance_tenancy      = "default"
  enable_dns_support    = "true"
  enable_dns_hostnames  = "true"
  enable_classiclink    = "false"
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-vpc"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
}

resource "aws_eip" "sellix-web-app-eip" {
  count             = local.production ? length(local.availability_zones) : 1
  vpc               = "true"
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-eip-${element(local.availability_zones, count.index)}"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_subnet" "sellix-web-app-public-subnet" {
  count                   = length(local.availability_zones)
  vpc_id                  = aws_vpc.sellix-web-app-vpc.id
  availability_zone       = element(local.availability_zones, count.index)
  cidr_block              = cidrsubnet(
    var.main_cidr_block,
    ceil(log(length(local.availability_zones) * 4, 2)),
    count.index
  )
  map_public_ip_on_launch = "true"
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-public-subnet-${element(local.availability_zones, count.index)}"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
}

resource "aws_subnet" "sellix-web-app-private-subnet" {
  count                   = length(local.availability_zones)
  vpc_id                  = aws_vpc.sellix-web-app-vpc.id
  availability_zone       = element(local.availability_zones, count.index)
  cidr_block              = cidrsubnet(
    var.main_cidr_block,
    ceil(log(length(local.availability_zones) * 4, 2)),
    length(local.availability_zones) + count.index
  )
  map_public_ip_on_launch = "false"
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-private-subnet-${element(local.availability_zones, count.index)}"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
}

resource "aws_nat_gateway" "sellix-web-app-nat-gateway" {
  count         = local.production ? length(local.availability_zones) : 1
  allocation_id = element(aws_eip.sellix-web-app-eip.*.id, count.index)
  subnet_id     = element(aws_subnet.sellix-web-app-public-subnet.*.id, count.index)
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-nat-gateway-${element(local.availability_zones, count.index)}"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_internet_gateway" "sellix-web-app-internet-gateway" {
  vpc_id  = aws_vpc.sellix-web-app-vpc.id
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-internet-gateway"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
}

resource "aws_route_table" "sellix-web-app-public-route-table" {
  vpc_id  = aws_vpc.sellix-web-app-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sellix-web-app-internet-gateway.id
  }
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-public-route-table"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
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
  tags = {
    "Name"  = "sellix-web-app-${terraform.workspace}-private-route-table-${element(local.availability_zones, count.index)}"
    "Project"     = "sellix-web-app-${terraform.workspace}"
    "Environment" = terraform.workspace
  }
}

resource "aws_route" "sellix-web-app-route" {
  route_table_id         = aws_route_table.sellix-web-app-public-route-table.id
  gateway_id             = aws_internet_gateway.sellix-web-app-internet-gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "sellix-web-app-public-route-table-association" {
  count           = length(local.availability_zones)
  subnet_id       = element(aws_subnet.sellix-web-app-public-subnet.*.id, count.index)
  route_table_id  = aws_route_table.sellix-web-app-public-route-table.id
}

resource "aws_route_table_association" "sellix-web-app-private-route-table-association" {
  count           = length(local.availability_zones)
  subnet_id       = element(aws_subnet.sellix-web-app-private-subnet.*.id, count.index)
  route_table_id  = local.production ? element(aws_route_table.sellix-web-app-private-route-table.*.id, count.index) : aws_route_table.sellix-web-app-private-route-table[0].id
}
