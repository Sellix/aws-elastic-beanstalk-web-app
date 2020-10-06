resource "aws_vpc" "web-app-vpc" {
  cidr_block            = var.main_cidr_block
  instance_tenancy      = "default"
  enable_dns_support    = "true"
  enable_dns_hostnames  = "true"
  enable_classiclink    = "false"
  tags = local.tags
}

resource "aws_subnet" "web-app-subnet" {
  vpc_id                  = aws_vpc.web-app-vpc.id
  availability_zone       = "eu-west-1a"
  cidr_block              = var.public_cidr_block
  map_public_ip_on_launch = "true"
  tags = local.tags
}

resource "aws_internet_gateway" "web-app-internet-gateway" {
  vpc_id  = aws_vpc.web-app-vpc.id
  tags = local.tags
}

resource "aws_route_table" "web-app-route-table" {
  vpc_id  = aws_vpc.web-app-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web-app-internet-gateway.id
  }
  tags = local.tags
}

resource "aws_route" "web-app-route" {
  route_table_id         = aws_route_table.web-app-route-table.id
  gateway_id             = aws_internet_gateway.web-app-internet-gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "web-app-route-table-association" {
  subnet_id       = aws_subnet.web-app-subnet.id
  route_table_id  = aws_route_table.web-app-route-table.id
}